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
