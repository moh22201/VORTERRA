create table if not exists public.player_employment_contracts (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.player_job_listings(id) on delete restrict,
  employer_id uuid not null references auth.users(id) on delete restrict,
  worker_id uuid not null references auth.users(id) on delete restrict,
  role text not null,
  wage_per_shift numeric(20,4) not null check (wage_per_shift > 0),
  status text not null default 'active' check (status in ('active','ended')),
  created_at timestamptz not null default now(),
  ended_at timestamptz,
  constraint employment_distinct_parties check (employer_id <> worker_id),
  constraint employment_status_timestamps check (
    (status='active' and ended_at is null) or
    (status='ended' and ended_at is not null)
  ),
  constraint employment_listing_worker_unique unique (listing_id, worker_id)
);

create index if not exists player_employment_employer_status_idx
  on public.player_employment_contracts (employer_id, status, created_at desc);
create index if not exists player_employment_worker_status_idx
  on public.player_employment_contracts (worker_id, status, created_at desc);

alter table public.player_employment_contracts enable row level security;
drop policy if exists employment_contracts_select_own on public.player_employment_contracts;
create policy employment_contracts_select_own
  on public.player_employment_contracts
  for select to authenticated
  using ((select auth.uid()) = employer_id or (select auth.uid()) = worker_id);

grant select on public.player_employment_contracts to authenticated;
revoke insert, update, delete on public.player_employment_contracts from anon, authenticated;

create or replace function private.respond_to_job_listing(p_listing_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_listing public.player_job_listings%rowtype;
  v_employer uuid;
  v_worker uuid;
  v_contract_id uuid;
  v_active_count integer;
  v_capacity integer;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
  if p_listing_id is null then raise exception 'Job listing is required' using errcode='22023'; end if;
  select * into v_listing from public.player_job_listings where id=p_listing_id for update;
  if not found or v_listing.status <> 'active' then raise exception 'This hiring post is no longer active' using errcode='P0002'; end if;
  if v_listing.owner_id = v_user then raise exception 'You cannot respond to your own hiring post' using errcode='42501'; end if;

  if v_listing.listing_type='offer' then
    v_employer := v_listing.owner_id;
    v_worker := v_user;
    v_capacity := greatest(coalesce(v_listing.workers,0),0);
    select count(*)::integer into v_active_count from public.player_employment_contracts where listing_id=v_listing.id and status='active';
    if v_active_count >= v_capacity then
      update public.player_job_listings set status='closed',updated_at=now() where id=v_listing.id;
      raise exception 'All positions in this offer have been filled' using errcode='23514';
    end if;
  elsif v_listing.listing_type='request' then
    v_employer := v_user;
    v_worker := v_listing.owner_id;
    if exists (select 1 from public.player_employment_contracts where listing_id=v_listing.id and status='active') then
      raise exception 'This applicant has already been hired' using errcode='23505';
    end if;
  else
    raise exception 'Unsupported hiring post type' using errcode='22023';
  end if;

  if coalesce(v_listing.wage,0) <= 0 then raise exception 'The listed wage must be greater than zero' using errcode='23514'; end if;

  insert into public.player_employment_contracts(listing_id,employer_id,worker_id,role,wage_per_shift)
  values(v_listing.id,v_employer,v_worker,v_listing.role,v_listing.wage)
  returning id into v_contract_id;

  if v_listing.listing_type='request' then
    update public.player_job_listings set status='closed',updated_at=now() where id=v_listing.id;
  else
    select count(*)::integer into v_active_count from public.player_employment_contracts where listing_id=v_listing.id and status='active';
    if v_active_count >= v_capacity then update public.player_job_listings set status='closed',updated_at=now() where id=v_listing.id; end if;
  end if;

  return jsonb_build_object('success',true,'contract_id',v_contract_id,'listing_id',v_listing.id,'employer_id',v_employer,'worker_id',v_worker,'role',v_listing.role,'wage_per_shift',v_listing.wage,'status','active');
end;
$function$;

create or replace function private.end_my_employment_contract(p_contract_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_contract public.player_employment_contracts%rowtype;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
  select * into v_contract from public.player_employment_contracts
   where id=p_contract_id and (employer_id=v_user or worker_id=v_user) for update;
  if not found then raise exception 'Employment contract not found' using errcode='P0002'; end if;
  if v_contract.status <> 'active' then raise exception 'Employment contract is already closed' using errcode='23514'; end if;
  update public.player_employment_contracts set status='ended',ended_at=now() where id=v_contract.id;
  return jsonb_build_object('success',true,'contract_id',v_contract.id,'status','ended');
end;
$function$;

revoke all on function private.respond_to_job_listing(uuid) from public, anon;
revoke all on function private.end_my_employment_contract(uuid) from public, anon;
grant execute on function private.respond_to_job_listing(uuid) to authenticated;
grant execute on function private.end_my_employment_contract(uuid) to authenticated;

create or replace function public.respond_to_job_listing(p_listing_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $function$ select private.respond_to_job_listing(p_listing_id); $function$;

create or replace function public.end_my_employment_contract(p_contract_id uuid)
returns jsonb language sql security invoker set search_path = ''
as $function$ select private.end_my_employment_contract(p_contract_id); $function$;

revoke all on function public.respond_to_job_listing(uuid) from public, anon;
revoke all on function public.end_my_employment_contract(uuid) from public, anon;
grant execute on function public.respond_to_job_listing(uuid) to authenticated;
grant execute on function public.end_my_employment_contract(uuid) to authenticated;
