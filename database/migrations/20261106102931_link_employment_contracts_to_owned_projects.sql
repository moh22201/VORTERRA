-- Link each employment contract to a project actively owned by the employer.
alter table public.player_job_listings
  add column project_id uuid references public.player_projects(id) on delete restrict;

alter table public.player_employment_contracts
  add column project_id uuid references public.player_projects(id) on delete restrict;

alter table public.player_job_listings
  add constraint player_job_listings_offer_project_required
  check (listing_type <> 'offer' or project_id is not null);

alter table public.player_employment_contracts
  add constraint player_employment_contracts_active_project_required
  check (status <> 'active' or project_id is not null);

create index player_job_listings_project_id_idx
  on public.player_job_listings(project_id)
  where project_id is not null;

create index player_employment_contracts_project_status_idx
  on public.player_employment_contracts(project_id, status);

create or replace function private.respond_to_job_listing(
  p_listing_id uuid,
  p_project_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_listing public.player_job_listings%rowtype;
  v_employer uuid;
  v_worker uuid;
  v_contract_id uuid;
  v_active_count integer;
  v_capacity integer;
  v_project_id uuid;
begin
  if v_user is null then
    raise exception 'Authentication required' using errcode='28000';
  end if;
  if p_listing_id is null then
    raise exception 'Job listing is required' using errcode='22023';
  end if;

  select * into v_listing
    from public.player_job_listings
   where id=p_listing_id
   for update;

  if not found or v_listing.status <> 'active' then
    raise exception 'This hiring post is no longer active' using errcode='P0002';
  end if;
  if v_listing.owner_id = v_user then
    raise exception 'You cannot respond to your own hiring post' using errcode='42501';
  end if;

  if v_listing.listing_type='offer' then
    v_employer := v_listing.owner_id;
    v_worker := v_user;
    v_project_id := v_listing.project_id;
    if v_project_id is null or (p_project_id is not null and p_project_id <> v_project_id) then
      raise exception 'This offer is not linked to a valid project' using errcode='23514';
    end if;
    v_capacity := greatest(coalesce(v_listing.workers,0),0);

    select count(*)::integer into v_active_count
      from public.player_employment_contracts
     where listing_id=v_listing.id and status='active';

    if v_active_count >= v_capacity then
      update public.player_job_listings set status='closed',updated_at=now() where id=v_listing.id;
      raise exception 'All positions in this offer have been filled' using errcode='23514';
    end if;
  elsif v_listing.listing_type='request' then
    v_employer := v_user;
    v_worker := v_listing.owner_id;
    v_project_id := p_project_id;
    if v_project_id is null then
      raise exception 'Choose one of your owned projects for this worker' using errcode='22023';
    end if;
    if exists (
      select 1 from public.player_employment_contracts
       where listing_id=v_listing.id and status='active'
    ) then
      raise exception 'This applicant has already been hired' using errcode='23505';
    end if;
  else
    raise exception 'Unsupported hiring post type' using errcode='22023';
  end if;

  if coalesce(v_listing.wage,0) <= 0 then
    raise exception 'The listed wage must be greater than zero' using errcode='23514';
  end if;

  if not exists (
    select 1
      from public.player_projects p
     where p.id=v_project_id
       and p.owner_id=v_employer
       and (p.acquisition_type='purchase' or (p.expires_at is not null and p.expires_at > now()))
  ) then
    raise exception 'The selected project is not actively owned by the employer' using errcode='42501';
  end if;

  insert into public.player_employment_contracts
    (listing_id,employer_id,worker_id,role,wage_per_shift,project_id)
  values
    (v_listing.id,v_employer,v_worker,v_listing.role,v_listing.wage,v_project_id)
  returning id into v_contract_id;

  if v_listing.listing_type='request' then
    update public.player_job_listings set status='closed',updated_at=now() where id=v_listing.id;
  else
    select count(*)::integer into v_active_count
      from public.player_employment_contracts
     where listing_id=v_listing.id and status='active';
    if v_active_count >= v_capacity then
      update public.player_job_listings set status='closed',updated_at=now() where id=v_listing.id;
    end if;
  end if;

  return jsonb_build_object(
    'success',true,
    'contract_id',v_contract_id,
    'listing_id',v_listing.id,
    'project_id',v_project_id,
    'employer_id',v_employer,
    'worker_id',v_worker,
    'role',v_listing.role,
    'wage_per_shift',v_listing.wage,
    'status','active'
  );
end;
$function$;

drop function if exists public.respond_to_job_listing(uuid);

create function public.respond_to_job_listing(
  p_listing_id uuid,
  p_project_id uuid
)
returns jsonb
language sql
security invoker
set search_path = ''
as $function$
  select private.respond_to_job_listing(p_listing_id,p_project_id);
$function$;

revoke all on function public.respond_to_job_listing(uuid,uuid) from public, anon;
grant execute on function public.respond_to_job_listing(uuid,uuid) to authenticated;
grant usage on schema private to authenticated;
grant execute on function private.respond_to_job_listing(uuid,uuid) to authenticated;
