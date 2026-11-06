-- Atomic VORTERRA project purchase and first-month rent.
-- Prices are mirrored from data/projects.json and intentionally server-authoritative.
create or replace function public.acquire_vorterra_project(
  p_project_key text, p_city_id uuid, p_acquisition_type text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_price numeric;
  v_project_id uuid;
  v_wallet public.wallets%rowtype;
  v_transaction_id uuid;
  v_expires_at timestamptz;
  v_circulated numeric := 0;
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_acquisition_type not in ('purchase','monthly_rent') then raise exception 'Invalid acquisition type'; end if;
  v_price := case p_project_key
    when 'quarry' then case p_acquisition_type when 'purchase' then 350 else 48 end
    when 'forest' then case p_acquisition_type when 'purchase' then 300 else 42 end
    when 'mine' then case p_acquisition_type when 'purchase' then 420 else 58 end
    when 'electricity' then case p_acquisition_type when 'purchase' then 500 else 70 end
    when 'water' then case p_acquisition_type when 'purchase' then 450 else 63 end
    when 'oil' then case p_acquisition_type when 'purchase' then 550 else 77 end
    when 'recycling' then case p_acquisition_type when 'purchase' then 380 else 53 end
    when 'city_storage' then case p_acquisition_type when 'purchase' then 130 else 45 end
    when 'road_transport' then case p_acquisition_type when 'purchase' then 600 else 39 end
    when 'sea_transport' then case p_acquisition_type when 'purchase' then 900 else 126 end
    when 'air_transport' then case p_acquisition_type when 'purchase' then 1200 else 168 end
    when 'maintenance' then case p_acquisition_type when 'purchase' then 500 else 35 end
    else null end;
  if v_price is null then raise exception 'Unknown project'; end if;
  if not exists(select 1 from public.player_cities c where c.id=p_city_id and c.owner_id=v_user_id)
    then raise exception 'Select a city that belongs to your account before acquiring a project'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text||':'||p_city_id::text||':'||p_project_key,0));
  if exists(select 1 from public.player_projects pp where pp.owner_id=v_user_id and pp.city_id=p_city_id
    and pp.project_key=p_project_key and (pp.acquisition_type='purchase'
      or (pp.acquisition_type='monthly_rent' and pp.expires_at>now())))
    then raise exception 'This project is already active in your city'; end if;
  select * into v_wallet from public.wallets where user_id=v_user_id and currency='VOR' for update;
  if not found then raise exception 'VOR wallet not found'; end if;
  if v_wallet.available_balance<v_price then
    raise exception 'Insufficient available VOR balance. Required: %, available: %',v_price,v_wallet.available_balance;
  end if;
  if p_acquisition_type='monthly_rent' then v_expires_at:=now()+interval '1 month'; end if;
  insert into public.player_projects(owner_id,city_id,project_key,acquisition_type,expires_at,condition_percent,operating_status,acquired_at,updated_at)
    values(v_user_id,p_city_id,p_project_key,p_acquisition_type,v_expires_at,100,'idle',now(),now())
    returning id into v_project_id;
  update public.wallets set available_balance=available_balance-v_price,total_balance=total_balance-v_price,updated_at=now()
    where user_id=v_user_id and currency='VOR';
  insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
    values(v_user_id,case when p_acquisition_type='purchase' then 'project_purchase' else 'project_monthly_rent' end,
      v_price,'VOR','completed','player_project',v_project_id,
      case when p_acquisition_type='purchase' then 'Project purchase: '||p_project_key else 'First month project rent: '||p_project_key end)
    returning id into v_transaction_id;
  if p_acquisition_type='purchase' then
    v_circulated:=private.record_loan_circulation(v_user_id,v_price,v_transaction_id);
  end if;
  return jsonb_build_object('success',true,'project_id',v_project_id,'project_key',p_project_key,
    'acquisition_type',p_acquisition_type,'amount_vor',v_price,'expires_at',v_expires_at,
    'wallet_transaction_id',v_transaction_id,'loan_circulated_vor',coalesce(v_circulated,0),
    'available_balance',v_wallet.available_balance-v_price,'total_balance',v_wallet.total_balance-v_price);
end;
$$;
revoke all on function public.acquire_vorterra_project(text,uuid,text) from public;
revoke all on function public.acquire_vorterra_project(text,uuid,text) from anon;
grant execute on function public.acquire_vorterra_project(text,uuid,text) to authenticated;
