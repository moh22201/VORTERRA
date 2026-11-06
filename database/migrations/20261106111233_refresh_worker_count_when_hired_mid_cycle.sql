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
