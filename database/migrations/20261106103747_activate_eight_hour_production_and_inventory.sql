create table private.project_production_rules (
  project_key text primary key,
  required_workers integer not null check (required_workers > 0),
  operating_cost_vor numeric(14,2) not null check (operating_cost_vor >= 0),
  output_items jsonb not null default '[]'::jsonb,
  input_items jsonb not null default '[]'::jsonb,
  enabled boolean not null default true
);
alter table private.project_production_rules enable row level security;
revoke all on private.project_production_rules from anon, authenticated;
insert into private.project_production_rules(project_key,required_workers,operating_cost_vor,output_items,input_items) values
('quarry',12,13,'[{"item":"raw_rock","quantity":120,"unit":"ton"},{"item":"crushed_gravel","quantity":70,"unit":"ton"},{"item":"manufactured_building_materials","quantity":40,"unit":"ton"}]','[]'),
('forest',10,12,'[{"item":"raw_wood","quantity":100,"unit":"ton"},{"item":"wood_panels","quantity":55,"unit":"ton"}]','[]'),
('mine',15,16,'[{"item":"raw_minerals","quantity":100,"unit":"ton"},{"item":"processed_minerals","quantity":60,"unit":"ton"},{"item":"concentrated_minerals","quantity":35,"unit":"ton"}]','[]'),
('electricity',12,8,'[{"item":"electricity","quantity":1200,"unit":"kWh"}]','[]'),
('water',12,11,'[{"item":"treated_water","quantity":600,"unit":"m3"}]','[]'),
('oil',16,15,'[{"item":"crude_oil","quantity":100,"unit":"barrel"},{"item":"refined_fuel","quantity":60,"unit":"barrel"},{"item":"petroleum_byproducts","quantity":30,"unit":"barrel"}]','[]'),
('recycling',12,13,'[{"item":"recycled_materials","quantity":75,"unit":"ton"},{"item":"plastic_materials","quantity":25,"unit":"ton"},{"item":"recovered_metals","quantity":20,"unit":"ton"}]','[{"item":"waste","quantity":120,"unit":"ton"}]')
on conflict(project_key) do update set required_workers=excluded.required_workers,operating_cost_vor=excluded.operating_cost_vor,output_items=excluded.output_items,input_items=excluded.input_items,enabled=true;
create table public.player_inventory (
 owner_id uuid not null references auth.users(id) on delete cascade,
 item_key text not null, unit text not null,
 quantity numeric(18,3) not null default 0 check(quantity>=0),
 updated_at timestamptz not null default now(),
 primary key(owner_id,item_key,unit)
);
alter table public.player_inventory enable row level security;
revoke all on public.player_inventory from anon,authenticated;
grant select on public.player_inventory to authenticated;
create policy "Players read their own inventory" on public.player_inventory for select to authenticated using((select auth.uid())=owner_id);
create table public.production_cycles (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 project_id uuid not null references public.player_projects(id) on delete restrict,
 project_key text not null,
 worker_count integer not null check(worker_count>0),
 wage_total_vor numeric(14,2) not null check(wage_total_vor>=0),
 operating_cost_vor numeric(14,2) not null check(operating_cost_vor>=0),
 reserved_total_vor numeric(14,2) not null check(reserved_total_vor>=0),
 output_items jsonb not null,input_items jsonb not null,
 status text not null default 'running' check(status in('running','completed','cancelled')),
 started_at timestamptz not null default now(),completes_at timestamptz not null,
 completed_at timestamptz,created_at timestamptz not null default now(),
 check(completes_at>started_at),
 check((status='completed')=(completed_at is not null))
);
create unique index production_cycles_one_running_per_project on public.production_cycles(project_id) where status='running';
create index production_cycles_owner_created_idx on public.production_cycles(owner_id,created_at desc);
alter table public.production_cycles enable row level security;
revoke all on public.production_cycles from anon,authenticated;
grant select on public.production_cycles to authenticated;
create policy "Players read their own production cycles" on public.production_cycles for select to authenticated using((select auth.uid())=owner_id);
create or replace function private.start_project_production(p_project_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $fn$
declare
 v_user uuid:=auth.uid(); v_project public.player_projects%rowtype; v_rule private.project_production_rules%rowtype;
 v_workers integer; v_wages numeric(14,2); v_reserve numeric(14,2); v_wallet public.wallets%rowtype;
 v_item jsonb; v_stock numeric(18,3); v_cycle uuid;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_project from public.player_projects where id=p_project_id and owner_id=v_user for update;
 if not found then raise exception 'Project not found or not owned by this player' using errcode='42501'; end if;
 if v_project.operating_status not in('idle','awaiting_clearance') then raise exception 'Project is not idle' using errcode='23514'; end if;
 if v_project.acquisition_type='monthly_rent' and v_project.expires_at<=now() then raise exception 'Project lease has expired' using errcode='23514'; end if;
 select * into v_rule from private.project_production_rules where project_key=v_project.project_key and enabled;
 if not found then raise exception 'This project does not have a production cycle' using errcode='22023'; end if;
 select count(*)::integer,coalesce(sum(wage_per_shift),0)::numeric(14,2) into v_workers,v_wages
 from public.player_employment_contracts where project_id=p_project_id and employer_id=v_user and status='active';
 if v_workers<v_rule.required_workers then raise exception 'Insufficient active workers: required %, assigned %',v_rule.required_workers,v_workers using errcode='23514'; end if;
 if exists(select 1 from public.production_cycles where project_id=p_project_id and status='running') then raise exception 'A production shift is already running' using errcode='23505'; end if;
 for v_item in select value from jsonb_array_elements(v_rule.input_items) loop
  select quantity into v_stock from public.player_inventory where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit' for update;
  if coalesce(v_stock,0)<(v_item->>'quantity')::numeric then raise exception 'Insufficient inventory for input %',v_item->>'item' using errcode='23514'; end if;
  update public.player_inventory set quantity=quantity-(v_item->>'quantity')::numeric,updated_at=now() where owner_id=v_user and item_key=v_item->>'item' and unit=v_item->>'unit';
 end loop;
 v_reserve:=v_wages+v_rule.operating_cost_vor;
 select * into v_wallet from public.wallets where user_id=v_user and currency='VOR' for update;
 if not found or v_wallet.available_balance<v_reserve then raise exception 'Insufficient available VOR to reserve wages and operating costs' using errcode='23514'; end if;
 update public.wallets set available_balance=available_balance-v_reserve,reserved_balance=reserved_balance+v_reserve,updated_at=now() where user_id=v_user and currency='VOR';
 insert into public.production_cycles(owner_id,project_id,project_key,worker_count,wage_total_vor,operating_cost_vor,reserved_total_vor,output_items,input_items,started_at,completes_at)
 values(v_user,p_project_id,v_project.project_key,v_workers,v_wages,v_rule.operating_cost_vor,v_reserve,v_rule.output_items,v_rule.input_items,now(),now()+interval '8 hours') returning id into v_cycle;
 update public.player_projects set operating_status='running',updated_at=now() where id=p_project_id;
 return jsonb_build_object('success',true,'cycle_id',v_cycle,'worker_count',v_workers,'wage_total_vor',v_wages,'operating_cost_vor',v_rule.operating_cost_vor,'reserved_total_vor',v_reserve,'completes_at',now()+interval '8 hours');
end;$fn$;
create or replace function private.complete_project_production(p_cycle_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $fn$
declare v_user uuid:=auth.uid(); v_cycle public.production_cycles%rowtype; v_item jsonb; v_outputs integer:=0;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_cycle from public.production_cycles where id=p_cycle_id and owner_id=v_user for update;
 if not found then raise exception 'Production cycle not found' using errcode='42501'; end if;
 if v_cycle.status<>'running' then raise exception 'Production cycle is not running' using errcode='23514'; end if;
 if now()<v_cycle.completes_at then raise exception 'The 8-hour shift has not finished yet' using errcode='23514'; end if;
 perform 1 from public.wallets where user_id=v_user and currency='VOR' for update;
 update public.wallets set total_balance=total_balance-v_cycle.reserved_total_vor,reserved_balance=reserved_balance-v_cycle.reserved_total_vor,updated_at=now()
 where user_id=v_user and currency='VOR' and reserved_balance>=v_cycle.reserved_total_vor;
 if not found then raise exception 'Reserved production funds are inconsistent' using errcode='23514'; end if;
 if v_cycle.wage_total_vor>0 then insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_user,'production_wage',v_cycle.wage_total_vor,'VOR','completed','production_cycle',v_cycle.id,'Worker wages for completed 8-hour production shift'); end if;
 if v_cycle.operating_cost_vor>0 then insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_user,'production_cost',v_cycle.operating_cost_vor,'VOR','completed','production_cycle',v_cycle.id,'Operating costs for completed 8-hour production shift'); end if;
 for v_item in select value from jsonb_array_elements(v_cycle.output_items) loop
  insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at) values(v_user,v_item->>'item',v_item->>'unit',(v_item->>'quantity')::numeric,now())
  on conflict(owner_id,item_key,unit) do update set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
  v_outputs:=v_outputs+1;
 end loop;
 update public.production_cycles set status='completed',completed_at=now() where id=v_cycle.id;
 update public.player_projects set operating_status='idle',updated_at=now() where id=v_cycle.project_id and owner_id=v_user;
 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'outputs_created',v_outputs,'wages_paid_vor',v_cycle.wage_total_vor,'operating_cost_vor',v_cycle.operating_cost_vor);
end;$fn$;
create or replace function private.cancel_project_production(p_cycle_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $fn$
declare v_user uuid:=auth.uid(); v_cycle public.production_cycles%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_cycle from public.production_cycles where id=p_cycle_id and owner_id=v_user for update;
 if not found then raise exception 'Production cycle not found' using errcode='42501'; end if;
 if v_cycle.status<>'running' then raise exception 'Production cycle is not running' using errcode='23514'; end if;
 update public.wallets set available_balance=available_balance+v_cycle.reserved_total_vor,reserved_balance=reserved_balance-v_cycle.reserved_total_vor,updated_at=now()
 where user_id=v_user and currency='VOR' and reserved_balance>=v_cycle.reserved_total_vor;
 if not found then raise exception 'Reserved production funds are inconsistent' using errcode='23514'; end if;
 update public.production_cycles set status='cancelled',completed_at=now() where id=v_cycle.id;
 update public.player_projects set operating_status='idle',updated_at=now() where id=v_cycle.project_id and owner_id=v_user;
 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'released_vor',v_cycle.reserved_total_vor);
end;$fn$;
create or replace function public.start_project_production(p_project_id uuid) returns jsonb language sql security invoker set search_path='' as $fn$ select private.start_project_production(p_project_id); $fn$;
create or replace function public.complete_project_production(p_cycle_id uuid) returns jsonb language sql security invoker set search_path='' as $fn$ select private.complete_project_production(p_cycle_id); $fn$;
create or replace function public.cancel_project_production(p_cycle_id uuid) returns jsonb language sql security invoker set search_path='' as $fn$ select private.cancel_project_production(p_cycle_id); $fn$;
revoke all on function public.start_project_production(uuid) from public,anon;
revoke all on function public.complete_project_production(uuid) from public,anon;
revoke all on function public.cancel_project_production(uuid) from public,anon;
grant execute on function public.start_project_production(uuid) to authenticated;
grant execute on function public.complete_project_production(uuid) to authenticated;
grant execute on function public.cancel_project_production(uuid) to authenticated;
grant usage on schema private to authenticated;
grant execute on function private.start_project_production(uuid) to authenticated;
grant execute on function private.complete_project_production(uuid) to authenticated;
grant execute on function private.cancel_project_production(uuid) to authenticated;