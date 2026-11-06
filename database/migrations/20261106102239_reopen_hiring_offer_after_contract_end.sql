create index if not exists player_employment_listing_status_idx
  on public.player_employment_contracts (listing_id, status);

create or replace function private.end_my_employment_contract(p_contract_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_contract public.player_employment_contracts%rowtype;
  v_listing public.player_job_listings%rowtype;
  v_active_count integer;
begin
  if v_user is null then
    raise exception 'Authentication required' using errcode='28000';
  end if;
  select * into v_contract
    from public.player_employment_contracts
   where id=p_contract_id
     and (employer_id=v_user or worker_id=v_user)
   for update;
  if not found then raise exception 'Employment contract not found' using errcode='P0002'; end if;
  if v_contract.status <> 'active' then raise exception 'Employment contract is already closed' using errcode='23514'; end if;
  update public.player_employment_contracts set status='ended',ended_at=now() where id=v_contract.id;
  select * into v_listing from public.player_job_listings where id=v_contract.listing_id for update;
  if found and v_listing.listing_type='offer' and v_listing.status='closed' then
    select count(*)::integer into v_active_count from public.player_employment_contracts where listing_id=v_listing.id and status='active';
    if v_active_count < coalesce(v_listing.workers,0) then
      update public.player_job_listings set status='active',updated_at=now() where id=v_listing.id;
    end if;
  end if;
  return jsonb_build_object('success',true,'contract_id',v_contract.id,'status','ended');
end;
$function$;

revoke all on function private.end_my_employment_contract(uuid) from public, anon;
grant execute on function private.end_my_employment_contract(uuid) to authenticated;
