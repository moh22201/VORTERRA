create table if not exists private.utility_station_stock (
  project_id uuid primary key references public.player_projects(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  utility_key text not null check (utility_key in ('electricity','water')),
  item_key text not null check (item_key in ('electricity','treated_water')),
  unit text not null check (unit in ('kWh','m3')),
  quantity numeric(18,3) not null default 0 check (quantity >= 0),
  capacity numeric(18,3) not null check (capacity > 0),
  updated_at timestamptz not null default now(),
  constraint station_quantity_within_capacity check (quantity <= capacity)
);
alter table private.utility_station_stock enable row level security;
revoke all on table private.utility_station_stock from public, anon, authenticated;

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
 v_contract record; v_station_quantity numeric:=0; v_station_capacity numeric:=0;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_project from public.player_projects where id=p_project_id and owner_id=v_user for update;
 if not found then raise exception 'Project not found or not owned by this player' using errcode='42501'; end if;
 if v_project.operating_status<>'idle' then raise exception 'Project is not idle' using errcode='23514'; end if;
 if v_project.acquisition_type='monthly_rent' and v_project.expires_at<=now() then raise exception 'Project lease has expired' using errcode='23514'; end if;
 select * into v_rule from private.project_production_rules where project_key=v_project.project_key and enabled;
 if not found then raise exception 'This project does not have a production cycle' using errcode='22023'; end if;
 if exists(select 1 from public.production_cycles where project_id=p_project_id and status='running') then
  raise exception 'A production shift is already running' using errcode='23505';
 end if;
 if v_project.project_key in ('electricity','water') then
   select coalesce(s.quantity,0),coalesce(s.capacity,case when v_project.project_key='electricity' then 10000 else 6000 end)
    into v_station_quantity,v_station_capacity
    from (select 1) seed left join private.utility_station_stock s on s.project_id=p_project_id;
   if v_station_quantity>=v_station_capacity then
     raise exception 'Utility station storage is full. Sell or deliver stored supply before starting another shift.' using errcode='23514';
   end if;
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
   select c.id from public.player_employment_contracts c
   left join private.project_worker_shifts s on s.contract_id=c.id
   where c.project_id=p_project_id and c.employer_id=v_user and c.status='active'
     and (s.contract_id is null or (s.completed_at is null and s.worked_seconds<28800)
       or (s.completed_at at time zone 'UTC')::date < (now() at time zone 'UTC')::date)
   order by c.created_at,c.id limit v_rule.required_workers
 loop
   perform private.start_worker_shift(v_contract.id,v_cycle,now());
 end loop;
 select count(*)::integer into v_workers from private.production_cycle_worker_time
  where cycle_id=v_cycle and started_at is not null;
 if v_workers=0 then
   raise exception 'At least one active worker is required. The station remains idle until workers are hired.' using errcode='23514';
 end if;
 update public.production_cycles set worker_count=v_workers where id=v_cycle;
 update public.player_projects set operating_status='running',updated_at=now() where id=p_project_id;
 return jsonb_build_object('success',true,'cycle_id',v_cycle,'worker_count',v_workers,
  'required_worker_count',v_rule.required_workers,'production_percent',50,
  'operating_cost_vor',v_rule.operating_cost_vor,'reserved_total_vor',v_reserve,'completes_at',now()+interval '8 hours');
end;
$function$
;
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
 v_utility_key text; v_item_key text; v_unit text;
 v_capacity numeric(18,3); v_station_quantity numeric(18,3); v_add_quantity numeric(18,3);
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_cycle from public.production_cycles where id=p_cycle_id and owner_id=v_user for update;
 if not found then raise exception 'Production cycle not found' using errcode='42501'; end if;
 if v_cycle.status<>'running' then raise exception 'Production cycle is not running' using errcode='23514'; end if;
 if now()<v_cycle.completes_at then raise exception 'The 8-hour production cycle has not finished yet' using errcode='23514'; end if;
 for v_worker in select contract_id from private.production_cycle_worker_time
   where cycle_id=v_cycle.id and started_at is not null
 loop perform private.pause_worker_shift(v_worker.contract_id,v_cycle.completes_at,false); end loop;
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
     update public.player_inventory set quantity=quantity-v_extra,updated_at=now()
      where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit' and quantity>=v_extra;
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
 if v_cycle.project_key in ('electricity','water') then
   v_utility_key:=v_cycle.project_key;
   for v_item in select value from jsonb_array_elements(v_cycle.output_items) loop
     v_item_key:=v_item->>'item'; v_unit:=v_item->>'unit';
     if v_utility_key='electricity' and v_item_key='electricity' and v_unit='kWh' then v_capacity:=10000;
     elsif v_utility_key='water' and v_item_key='treated_water' and v_unit='m3' then v_capacity:=6000;
     else raise exception 'Unexpected utility station output definition' using errcode='23514'; end if;
     insert into private.utility_station_stock(project_id,owner_id,utility_key,item_key,unit,quantity,capacity)
     values(v_cycle.project_id,v_user,v_utility_key,v_item_key,v_unit,0,v_capacity)
     on conflict(project_id) do nothing;
     select quantity,capacity into v_station_quantity,v_capacity
       from private.utility_station_stock where project_id=v_cycle.project_id for update;
     v_quantity:=round((v_item->>'quantity')::numeric*(v_final_percent/100.0),3);
     v_add_quantity:=least(greatest(v_capacity-v_station_quantity,0),v_quantity);
     update private.utility_station_stock set quantity=quantity+v_add_quantity,updated_at=now()
       where project_id=v_cycle.project_id;
     if v_add_quantity>0 then v_outputs:=v_outputs+1; end if;
   end loop;
 else
   select count(*)::integer into v_outputs from jsonb_array_elements(v_cycle.output_items) as output(value)
    where round((output.value->>'quantity')::numeric*(v_final_percent/100.0),3)>0;
 end if;
 for v_worker in select contract_id from private.project_worker_shifts
   where project_id=v_cycle.project_id and worked_seconds>=28800 and wage_reserved=true and completed_at is null
 loop perform private.pause_worker_shift(v_worker.contract_id,v_cycle.completes_at,false); end loop;
 update public.production_cycles set status='completed',completed_at=now(),
  production_percent=v_final_percent,wage_total_vor=0,wage_payments='[]'::jsonb where id=v_cycle.id;
 update public.player_projects set operating_status='awaiting_clearance',updated_at=now()
  where id=v_cycle.project_id and owner_id=v_user;
 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'outputs_created',v_outputs,
  'production_percent',v_final_percent,'worker_seconds',v_total_worker_seconds,
  'worker_count',v_cycle.worker_count,'required_worker_count',v_cycle.required_worker_count,
  'wages_paid_vor',0,'operating_cost_vor',v_cycle.operating_cost_vor);
end;
$function$
;
create or replace function public.transfer_completed_production(p_cycle_id uuid)
 returns jsonb language sql set search_path to ''
as $function$
 select private.transfer_completed_production(p_cycle_id);
$function$;

revoke all on function private.start_project_production(uuid) from public,anon,authenticated;
grant execute on function private.start_project_production(uuid) to authenticated;
revoke all on function private.complete_project_production(uuid) from public,anon,authenticated;
grant execute on function private.complete_project_production(uuid) to authenticated;
revoke all on function private.transfer_completed_production(uuid) from public,anon,authenticated;
grant execute on function private.transfer_completed_production(uuid) to authenticated;
revoke all on function public.transfer_completed_production(uuid) from public,anon;
grant execute on function public.transfer_completed_production(uuid) to authenticated;
