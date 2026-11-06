
-- VORTERRA worker shifts only accrue while a production cycle is active.
create table if not exists private.project_worker_shifts (
  contract_id uuid primary key references public.player_employment_contracts(id) on delete cascade,
  project_id uuid not null references public.player_projects(id) on delete cascade,
  employer_id uuid not null,
  worker_id uuid not null,
  wage_per_shift numeric(14,2) not null check (wage_per_shift >= 0),
  worked_seconds integer not null default 0 check (worked_seconds between 0 and 28800),
  wage_reserved boolean not null default false,
  shift_started_at timestamptz,
  completed_at timestamptz,
  shift_day date not null default ((now() at time zone 'UTC')::date),
  updated_at timestamptz not null default now()
);
create table if not exists private.production_cycle_worker_time (
  cycle_id uuid not null references public.production_cycles(id) on delete cascade,
  contract_id uuid not null references public.player_employment_contracts(id) on delete cascade,
  worker_id uuid not null,
  started_at timestamptz,
  worked_seconds integer not null default 0 check (worked_seconds between 0 and 28800),
  primary key (cycle_id,contract_id)
);
create index if not exists project_worker_shifts_project_idx on private.project_worker_shifts(project_id,completed_at);
create index if not exists production_cycle_worker_time_contract_idx on private.production_cycle_worker_time(contract_id);
revoke all on private.project_worker_shifts from public,anon,authenticated;
revoke all on private.production_cycle_worker_time from public,anon,authenticated;

CREATE OR REPLACE FUNCTION private.start_worker_shift(p_contract_id uuid, p_cycle_id uuid, p_started_at timestamp with time zone)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_contract public.player_employment_contracts%rowtype;
  v_shift private.project_worker_shifts%rowtype;
  v_wallet public.wallets%rowtype;
  v_today date := (p_started_at at time zone 'UTC')::date;
begin
  select * into v_contract
    from public.player_employment_contracts
   where id=p_contract_id and status='active'
   for update;
  if not found then return; end if;

  insert into private.project_worker_shifts(contract_id,project_id,employer_id,worker_id,wage_per_shift)
  values(v_contract.id,v_contract.project_id,v_contract.employer_id,v_contract.worker_id,v_contract.wage_per_shift)
  on conflict(contract_id) do nothing;

  select * into v_shift from private.project_worker_shifts where contract_id=p_contract_id for update;

  if v_shift.completed_at is not null and (v_shift.completed_at at time zone 'UTC')::date < v_today then
    update private.project_worker_shifts
       set worked_seconds=0,completed_at=null,wage_reserved=false,shift_started_at=null,
           shift_day=v_today,wage_per_shift=v_contract.wage_per_shift,updated_at=now()
     where contract_id=p_contract_id;
    select * into v_shift from private.project_worker_shifts where contract_id=p_contract_id for update;
  end if;

  if v_shift.completed_at is not null or v_shift.worked_seconds >= 28800 then return; end if;

  if not v_shift.wage_reserved then
    select * into v_wallet from public.wallets
     where user_id=v_contract.employer_id and currency='VOR' for update;
    if not found or v_wallet.available_balance < v_contract.wage_per_shift then
      raise exception 'Insufficient available VOR to reserve the worker daily wage' using errcode='23514';
    end if;
    update public.wallets
       set available_balance=available_balance-v_contract.wage_per_shift,
           reserved_balance=reserved_balance+v_contract.wage_per_shift,updated_at=now()
     where user_id=v_contract.employer_id and currency='VOR';
    update private.project_worker_shifts
       set wage_reserved=true,wage_per_shift=v_contract.wage_per_shift,updated_at=now()
     where contract_id=p_contract_id;
  end if;

  update private.project_worker_shifts
     set shift_started_at=coalesce(shift_started_at,p_started_at),updated_at=now()
   where contract_id=p_contract_id;

  insert into private.production_cycle_worker_time(cycle_id,contract_id,worker_id,started_at)
  values(p_cycle_id,p_contract_id,v_contract.worker_id,p_started_at)
  on conflict(cycle_id,contract_id) do nothing;

  update public.production_cycles
     set worker_count=(select count(*)::integer from private.production_cycle_worker_time
                        where cycle_id=p_cycle_id and started_at is not null)
   where id=p_cycle_id and status='running';
end;
$function$


CREATE OR REPLACE FUNCTION private.pause_worker_shift(p_contract_id uuid, p_paused_at timestamp with time zone, p_settle boolean DEFAULT false)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_shift private.project_worker_shifts%rowtype;
  v_contract public.player_employment_contracts%rowtype;
  v_log private.production_cycle_worker_time%rowtype;
  v_elapsed integer := 0;
  v_pay numeric(14,2) := 0;
  v_refund numeric(14,2) := 0;
begin
  select * into v_shift from private.project_worker_shifts
   where contract_id=p_contract_id for update;
  if not found then return 0; end if;

  if v_shift.shift_started_at is not null then
    v_elapsed := least(28800-v_shift.worked_seconds,
      greatest(0,floor(extract(epoch from (p_paused_at-v_shift.shift_started_at)))::integer));
    v_elapsed := greatest(0,v_elapsed);

    update private.production_cycle_worker_time
       set worked_seconds=least(28800,worked_seconds+v_elapsed),started_at=null
     where contract_id=p_contract_id and started_at is not null;

    update private.project_worker_shifts
       set worked_seconds=least(28800,worked_seconds+v_elapsed),
           shift_started_at=null,updated_at=now()
     where contract_id=p_contract_id
     returning * into v_shift;
  end if;

  if p_settle and v_shift.wage_reserved then
    v_pay := round(v_shift.wage_per_shift * v_shift.worked_seconds / 28800.0,2);
    v_refund := greatest(0,v_shift.wage_per_shift-v_pay);

    update public.wallets
       set total_balance=total_balance-v_pay,
           reserved_balance=reserved_balance-v_shift.wage_per_shift,
           available_balance=available_balance+v_refund,
           updated_at=now()
     where user_id=v_shift.employer_id and currency='VOR'
       and reserved_balance>=v_shift.wage_per_shift;
    if not found then
      raise exception 'Reserved worker wage is inconsistent' using errcode='23514';
    end if;

    if v_pay>0 then
      insert into public.wallets(user_id,currency,total_balance,available_balance,reserved_balance)
      values(v_shift.worker_id,'VOR',v_pay,v_pay,0)
      on conflict(user_id) do update
        set total_balance=public.wallets.total_balance+excluded.total_balance,
            available_balance=public.wallets.available_balance+excluded.available_balance,
            updated_at=now();

      insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
      values(v_shift.worker_id,'wage_income',v_pay,'VOR','completed','employment_contract',p_contract_id,
        'Prorated wages for active production time');
      insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
      values(v_shift.employer_id,'production_wage',v_pay,'VOR','completed','employment_contract',p_contract_id,
        'Worker wages for active production time');
    end if;

    update private.project_worker_shifts
       set wage_reserved=false,completed_at=p_paused_at,updated_at=now()
     where contract_id=p_contract_id;
  elsif v_shift.worked_seconds>=28800 and v_shift.wage_reserved then
    v_pay := v_shift.wage_per_shift;
    update public.wallets
       set total_balance=total_balance-v_pay,
           reserved_balance=reserved_balance-v_pay,
           updated_at=now()
     where user_id=v_shift.employer_id and currency='VOR'
       and reserved_balance>=v_pay;
    if not found then
      raise exception 'Reserved worker wage is inconsistent' using errcode='23514';
    end if;

    insert into public.wallets(user_id,currency,total_balance,available_balance,reserved_balance)
    values(v_shift.worker_id,'VOR',v_pay,v_pay,0)
    on conflict(user_id) do update
      set total_balance=public.wallets.total_balance+excluded.total_balance,
          available_balance=public.wallets.available_balance+excluded.available_balance,
          updated_at=now();

    insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
    values(v_shift.worker_id,'wage_income',v_pay,'VOR','completed','employment_contract',p_contract_id,
      'Daily wages after 8 active production hours');
    insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
    values(v_shift.employer_id,'production_wage',v_pay,'VOR','completed','employment_contract',p_contract_id,
      'Daily worker wages after 8 active production hours');

    update private.project_worker_shifts
       set wage_reserved=false,completed_at=p_paused_at,updated_at=now()
     where contract_id=p_contract_id;
  end if;

  return v_pay;
end;
$function$


CREATE OR REPLACE FUNCTION private.handle_employment_shift_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_cycle public.production_cycles%rowtype;
  v_active_workers integer;
begin
  if tg_op='UPDATE' and old.status='active' and new.status<>'active' then
    perform private.pause_worker_shift(new.id,coalesce(new.ended_at,now()),true);
    return new;
  end if;

  if new.status='active' and new.project_id is not null then
    insert into private.project_worker_shifts(contract_id,project_id,employer_id,worker_id,wage_per_shift)
    values(new.id,new.project_id,new.employer_id,new.worker_id,new.wage_per_shift)
    on conflict(contract_id) do nothing;

    select * into v_cycle
      from public.production_cycles
     where project_id=new.project_id and owner_id=new.employer_id and status='running'
     order by started_at desc limit 1;

    if found then
      select count(*)::integer into v_active_workers
        from private.production_cycle_worker_time
       where cycle_id=v_cycle.id and started_at is not null;
      if v_active_workers < v_cycle.required_worker_count then
        perform private.start_worker_shift(new.id,v_cycle.id,now());
      end if;
    end if;
  end if;
  return new;
end;
$function$


CREATE OR REPLACE FUNCTION private.start_project_production(p_project_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_user uuid:=auth.uid(); v_project public.player_projects%rowtype;
 v_rule private.project_production_rules%rowtype; v_workers integer:=0;
 v_reserve numeric(14,2); v_wallet public.wallets%rowtype;
 v_item jsonb; v_stock numeric; v_needed numeric; v_cycle uuid;
 v_contract record;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_project from public.player_projects where id=p_project_id and owner_id=v_user for update;
 if not found then raise exception 'Project not found or not owned by this player' using errcode='42501'; end if;
 if v_project.operating_status not in('idle','awaiting_clearance') then raise exception 'Project is not idle' using errcode='23514'; end if;
 if v_project.acquisition_type='monthly_rent' and v_project.expires_at<=now() then raise exception 'Project lease has expired' using errcode='23514'; end if;
 select * into v_rule from private.project_production_rules where project_key=v_project.project_key and enabled;
 if not found then raise exception 'This project does not have a production cycle' using errcode='22023'; end if;
 if exists(select 1 from public.production_cycles where project_id=p_project_id and status='running') then
  raise exception 'A production shift is already running' using errcode='23505';
 end if;

 for v_item in select value from jsonb_array_elements(v_rule.input_items) loop
  v_needed:=round((v_item->>'quantity')::numeric*0.5,3);
  select quantity into v_stock from public.player_inventory
   where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit' for update;
  if coalesce(v_stock,0)<v_needed then
   raise exception 'Insufficient inventory for base input %',v_item->>'item' using errcode='23514';
  end if;
  if v_needed>0 then
   update public.player_inventory set quantity=quantity-v_needed,updated_at=now()
   where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit';
  end if;
 end loop;

 v_reserve:=v_rule.operating_cost_vor;
 select * into v_wallet from public.wallets where user_id=v_user and currency='VOR' for update;
 if not found or v_wallet.available_balance<v_reserve then
  raise exception 'Insufficient available VOR to reserve operating costs' using errcode='23514';
 end if;
 update public.wallets set available_balance=available_balance-v_reserve,
  reserved_balance=reserved_balance+v_reserve,updated_at=now()
 where user_id=v_user and currency='VOR';

 insert into public.production_cycles(owner_id,project_id,project_key,worker_count,required_worker_count,production_percent,
  wage_total_vor,operating_cost_vor,reserved_total_vor,output_items,input_items,wage_payments,started_at,completes_at)
 values(v_user,p_project_id,v_project.project_key,0,v_rule.required_workers,50,
  0,v_rule.operating_cost_vor,v_reserve,v_rule.output_items,v_rule.input_items,'[]'::jsonb,now(),now()+interval '8 hours')
 returning id into v_cycle;

 for v_contract in
   select c.id
     from public.player_employment_contracts c
     left join private.project_worker_shifts s on s.contract_id=c.id
    where c.project_id=p_project_id and c.employer_id=v_user and c.status='active'
      and (s.contract_id is null
        or (s.completed_at is null and s.worked_seconds<28800)
        or (s.completed_at at time zone 'UTC')::date < (now() at time zone 'UTC')::date)
    order by c.created_at,c.id
    limit v_rule.required_workers
 loop
   perform private.start_worker_shift(v_contract.id,v_cycle,now());
 end loop;

 select count(*)::integer into v_workers
   from private.production_cycle_worker_time
  where cycle_id=v_cycle and started_at is not null;

 update public.production_cycles set worker_count=v_workers where id=v_cycle;
 update public.player_projects set operating_status='running',updated_at=now() where id=p_project_id;

 return jsonb_build_object('success',true,'cycle_id',v_cycle,'worker_count',v_workers,
  'required_worker_count',v_rule.required_workers,'production_percent',50,
  'operating_cost_vor',v_rule.operating_cost_vor,'reserved_total_vor',v_reserve,'completes_at',now()+interval '8 hours');
end;
$function$


CREATE OR REPLACE FUNCTION private.complete_project_production(p_cycle_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_user uuid:=auth.uid(); v_cycle public.production_cycles%rowtype; v_item jsonb;
 v_outputs integer:=0; v_quantity numeric(18,3); v_total_worker_seconds bigint;
 v_final_percent numeric(5,2); v_candidate numeric(5,2); v_extra numeric(18,3);
 v_stock numeric; v_ratio numeric; v_worker record;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_cycle from public.production_cycles where id=p_cycle_id and owner_id=v_user for update;
 if not found then raise exception 'Production cycle not found' using errcode='42501'; end if;
 if v_cycle.status<>'running' then raise exception 'Production cycle is not running' using errcode='23514'; end if;
 if now()<v_cycle.completes_at then raise exception 'The 8-hour production cycle has not finished yet' using errcode='23514'; end if;

 for v_worker in
   select contract_id from private.production_cycle_worker_time
    where cycle_id=v_cycle.id and started_at is not null
 loop
   perform private.pause_worker_shift(v_worker.contract_id,v_cycle.completes_at,false);
 end loop;

 select coalesce(sum(worked_seconds),0)::bigint into v_total_worker_seconds
   from private.production_cycle_worker_time where cycle_id=v_cycle.id;

 v_final_percent:=50+(50.0*least(v_total_worker_seconds,v_cycle.required_worker_count::bigint*28800)
    /(v_cycle.required_worker_count::bigint*28800));
 v_candidate:=v_final_percent;

 for v_item in select value from jsonb_array_elements(v_cycle.input_items) loop
   v_extra:=round((v_item->>'quantity')::numeric*((v_final_percent-50)/100.0),3);
   if v_extra>0 then
     select quantity into v_stock from public.player_inventory
      where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit' for update;
     v_ratio:=least(1,coalesce(v_stock,0)/v_extra);
     v_candidate:=least(v_candidate,50+((v_final_percent-50)*v_ratio));
   end if;
 end loop;
 v_final_percent:=v_candidate;

 for v_item in select value from jsonb_array_elements(v_cycle.input_items) loop
   v_extra:=round((v_item->>'quantity')::numeric*((v_final_percent-50)/100.0),3);
   if v_extra>0 then
     update public.player_inventory
        set quantity=quantity-v_extra,updated_at=now()
      where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit'
        and quantity>=v_extra;
     if not found then raise exception 'Inventory changed while settling additional production inputs' using errcode='23514'; end if;
   end if;
 end loop;

 perform 1 from public.wallets where user_id=v_user and currency='VOR' for update;
 update public.wallets set total_balance=total_balance-v_cycle.operating_cost_vor,
  reserved_balance=reserved_balance-v_cycle.reserved_total_vor,updated_at=now()
 where user_id=v_user and currency='VOR' and reserved_balance>=v_cycle.reserved_total_vor;
 if not found then raise exception 'Reserved production funds are inconsistent' using errcode='23514'; end if;

 if v_cycle.operating_cost_vor>0 then
  insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
  values(v_user,'production_cost',v_cycle.operating_cost_vor,'VOR','completed','production_cycle',v_cycle.id,'Operating costs for completed 8-hour production cycle');
 end if;

 for v_item in select value from jsonb_array_elements(v_cycle.output_items) loop
  v_quantity:=round((v_item->>'quantity')::numeric*(v_final_percent/100.0),3);
  if v_quantity>0 then
   insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at)
   values(v_user,v_item->>'item',v_item->>'unit',v_quantity,now())
   on conflict(owner_id,item_key,unit) do update
    set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
   v_outputs:=v_outputs+1;
  end if;
 end loop;

 for v_worker in
   select contract_id from private.project_worker_shifts
    where project_id=v_cycle.project_id and worked_seconds>=28800
      and wage_reserved=true and completed_at is null
 loop
   perform private.pause_worker_shift(v_worker.contract_id,v_cycle.completes_at,false);
 end loop;

 update public.production_cycles set status='completed',completed_at=now(),
  production_percent=v_final_percent,wage_total_vor=0,wage_payments='[]'::jsonb
 where id=v_cycle.id;
 update public.player_projects set operating_status='idle',updated_at=now()
 where id=v_cycle.project_id and owner_id=v_user;

 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'outputs_created',v_outputs,
  'production_percent',v_final_percent,'worker_seconds',v_total_worker_seconds,
  'worker_count',v_cycle.worker_count,'required_worker_count',v_cycle.required_worker_count,
  'wages_paid_vor',0,'operating_cost_vor',v_cycle.operating_cost_vor);
end;
$function$


CREATE OR REPLACE FUNCTION private.cancel_project_production(p_cycle_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_cycle public.production_cycles%rowtype; v_item jsonb; v_worker record;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_cycle from public.production_cycles where id=p_cycle_id and owner_id=v_user for update;
 if not found then raise exception 'Production cycle not found' using errcode='42501'; end if;
 if v_cycle.status<>'running' then raise exception 'Production cycle is not running' using errcode='23514'; end if;
 if now()>=v_cycle.completes_at then raise exception 'The production cycle has finished and must be settled, not cancelled' using errcode='23514'; end if;

 for v_worker in
   select contract_id from private.production_cycle_worker_time
    where cycle_id=v_cycle.id and started_at is not null
 loop
   perform private.pause_worker_shift(v_worker.contract_id,now(),false);
 end loop;

 update public.wallets set available_balance=available_balance+v_cycle.reserved_total_vor,
  reserved_balance=reserved_balance-v_cycle.reserved_total_vor,updated_at=now()
 where user_id=v_user and currency='VOR' and reserved_balance>=v_cycle.reserved_total_vor;
 if not found then raise exception 'Reserved production funds are inconsistent' using errcode='23514'; end if;

 -- Return only the 50% base inputs consumed when this cycle started.
 for v_item in select value from jsonb_array_elements(v_cycle.input_items) loop
  insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at)
  values(v_user,v_item->>'item',v_item->>'unit',round((v_item->>'quantity')::numeric*0.5,3),now())
  on conflict(owner_id,item_key,unit) do update
   set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
 end loop;

 update public.production_cycles set status='cancelled',completed_at=now() where id=v_cycle.id;
 update public.player_projects set operating_status='idle',updated_at=now() where id=v_cycle.project_id and owner_id=v_user;
 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'released_vor',v_cycle.reserved_total_vor);
end;
$function$


drop trigger if exists employment_shift_change on public.player_employment_contracts;
create trigger employment_shift_change
after insert or update of status on public.player_employment_contracts
for each row execute function private.handle_employment_shift_change();

revoke all on function private.start_worker_shift(uuid,uuid,timestamptz) from public,anon,authenticated;
revoke all on function private.pause_worker_shift(uuid,timestamptz,boolean) from public,anon,authenticated;
revoke all on function private.handle_employment_shift_change() from public,anon,authenticated;
revoke all on function private.start_project_production(uuid) from public,anon,authenticated;
revoke all on function private.complete_project_production(uuid) from public,anon,authenticated;
revoke all on function private.cancel_project_production(uuid) from public,anon,authenticated;
