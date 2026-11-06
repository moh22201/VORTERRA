alter table public.market_listings add column if not exists unit text;
alter table public.market_listings add column if not exists project_id uuid references public.player_projects(id) on delete restrict;
alter table public.market_listings add column if not exists lease_months integer;
alter table public.market_listings add constraint market_listing_project_rent_payload_check check ((listing_type='sale' and project_id is null and lease_months is null and unit is not null) or (listing_type='rent' and project_id is not null and lease_months in (1,3)));
create unique index market_listings_one_active_project_rent on public.market_listings(project_id) where listing_type='rent' and status='active';
alter table public.player_projects add column if not exists leased_from_project_id uuid references public.player_projects(id) on delete restrict;
alter table public.player_projects add column if not exists market_listing_id uuid references public.market_listings(id) on delete restrict;
create unique index player_projects_market_listing_unique on public.player_projects(market_listing_id) where market_listing_id is not null;
create table private.project_rent_price_caps(project_key text primary key,max_monthly_rent_vor numeric(14,2) not null check(max_monthly_rent_vor>0));
alter table private.project_rent_price_caps enable row level security;
revoke all on private.project_rent_price_caps from anon,authenticated;
insert into private.project_rent_price_caps(project_key,max_monthly_rent_vor) values ('quarry',48),('forest',42),('mine',58),('electricity',70),('water',63),('oil',77),('recycling',53),('city_storage',45),('road_transport',39),('sea_transport',126),('air_transport',168),('maintenance',35) on conflict(project_key) do update set max_monthly_rent_vor=excluded.max_monthly_rent_vor;
drop policy if exists "Players can create their own market listings" on public.market_listings;
drop policy if exists "Players can delete their own market listings" on public.market_listings;
drop policy if exists "Players can update their own market listings" on public.market_listings;
revoke insert,update,delete on public.market_listings from anon,authenticated;
grant select on public.market_listings to authenticated;
create table public.player_transport_contracts(
 id uuid primary key default gen_random_uuid(),
 requester_id uuid not null references auth.users(id) on delete cascade,
 provider_id uuid references auth.users(id) on delete restrict,
 transport_project_id uuid references public.player_projects(id) on delete restrict,
 cargo_description text not null,quantity numeric(18,3) not null check(quantity>0),unit text not null,
 pickup_location text not null,delivery_location text not null,price_vor numeric(14,2) not null check(price_vor>0),
 status text not null default 'open' check(status in('open','accepted','in_transit','delivered','cancelled')),
 created_at timestamptz not null default now(),accepted_at timestamptz,started_at timestamptz,delivered_at timestamptz,updated_at timestamptz not null default now(),
 check(requester_id<>provider_id),check((status in('accepted','in_transit','delivered'))=(provider_id is not null)),
 check((status='delivered')=(delivered_at is not null)),check((status in('in_transit','delivered'))=(started_at is not null))
);
create index player_transport_contracts_open_idx on public.player_transport_contracts(status,created_at desc);
create index player_transport_contracts_parties_idx on public.player_transport_contracts(requester_id,provider_id,status);
alter table public.player_transport_contracts enable row level security;
revoke all on public.player_transport_contracts from anon,authenticated;
grant select on public.player_transport_contracts to authenticated;
create policy "Transport parties read their contracts" on public.player_transport_contracts for select to authenticated using((select auth.uid())=requester_id or (select auth.uid())=provider_id);
CREATE OR REPLACE FUNCTION private.accept_transport_contract(p_contract_id uuid, p_transport_project_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_contract public.player_transport_contracts%rowtype; v_project public.player_projects%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_contract from public.player_transport_contracts where id=p_contract_id for update;
 if not found or v_contract.status<>'open' then raise exception 'Transport request is no longer open' using errcode='P0002'; end if;
 if v_contract.requester_id=v_user then raise exception 'You cannot transport your own request' using errcode='42501'; end if;
 select * into v_project from public.player_projects where id=p_transport_project_id and owner_id=v_user for update;
 if not found or v_project.project_key not in('road_transport','sea_transport','air_transport') or v_project.operating_status not in('idle','awaiting_clearance') or (v_project.acquisition_type='monthly_rent' and v_project.expires_at<=now()) then
  raise exception 'Choose an active transport project that you own or rent' using errcode='42501';
 end if;
 update public.player_transport_contracts set provider_id=v_user,transport_project_id=v_project.id,status='accepted',accepted_at=now(),updated_at=now() where id=v_contract.id;
 return jsonb_build_object('success',true,'contract_id',v_contract.id,'status','accepted');
end;$function$


CREATE OR REPLACE FUNCTION private.buy_market_sale_listing(p_listing_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_listing public.market_listings%rowtype; v_total numeric(14,2); v_buyer public.wallets%rowtype; v_seller public.wallets%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_listing from public.market_listings where id=p_listing_id and listing_type='sale' for update;
 if not found or v_listing.status<>'active' then raise exception 'Sale listing is no longer available' using errcode='P0002'; end if;
 if v_listing.owner_id=v_user then raise exception 'You cannot buy your own listing' using errcode='42501'; end if;
 v_total:=round(v_listing.quantity*v_listing.unit_price,2);
 perform 1 from public.wallets where user_id in(v_user,v_listing.owner_id) and currency='VOR' order by user_id for update;
 select * into v_buyer from public.wallets where user_id=v_user and currency='VOR';
 select * into v_seller from public.wallets where user_id=v_listing.owner_id and currency='VOR';
 if v_buyer.user_id is null or v_seller.user_id is null then raise exception 'A buyer or seller wallet is missing' using errcode='23514'; end if;
 if v_buyer.available_balance<v_total then raise exception 'Insufficient available VOR' using errcode='23514'; end if;
 update public.wallets set total_balance=total_balance-v_total,available_balance=available_balance-v_total,updated_at=now() where user_id=v_user;
 update public.wallets set total_balance=total_balance+v_total,available_balance=available_balance+v_total,updated_at=now() where user_id=v_listing.owner_id;
 insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at)
 values(v_user,v_listing.product_name,coalesce(v_listing.unit,'unit'),v_listing.quantity,now())
 on conflict(owner_id,item_key,unit) do update set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
 insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_user,'market_purchase',v_total,'VOR','completed','market_listing',v_listing.id,'Purchased inventory from another player');
 insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_listing.owner_id,'market_sale',v_total,'VOR','completed','market_listing',v_listing.id,'Sold inventory to another player');
 update public.market_listings set status='closed',updated_at=now() where id=v_listing.id;
 return jsonb_build_object('success',true,'listing_id',v_listing.id,'quantity',v_listing.quantity,'total_vor',v_total);
end;$function$


CREATE OR REPLACE FUNCTION private.cancel_market_listing(p_listing_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_listing public.market_listings%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_listing from public.market_listings where id=p_listing_id and owner_id=v_user for update;
 if not found or v_listing.status<>'active' then raise exception 'Listing not found or already closed' using errcode='P0002'; end if;
 if v_listing.listing_type='sale' then
  insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at)
  values(v_user,v_listing.product_name,coalesce(v_listing.unit,'unit'),v_listing.quantity,now())
  on conflict(owner_id,item_key,unit) do update set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
 end if;
 update public.market_listings set status='cancelled',updated_at=now() where id=v_listing.id;
 return jsonb_build_object('success',true,'listing_id',v_listing.id);
end;$function$


CREATE OR REPLACE FUNCTION private.cancel_transport_contract(p_contract_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_contract public.player_transport_contracts%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_contract from public.player_transport_contracts where id=p_contract_id for update;
 if not found or (v_contract.requester_id<>v_user and coalesce(v_contract.provider_id,'00000000-0000-0000-0000-000000000000'::uuid)<>v_user) then raise exception 'Transport contract not found' using errcode='42501'; end if;
 if v_contract.status not in('open','accepted') then raise exception 'A transport already in transit cannot be cancelled' using errcode='23514'; end if;
 update public.wallets set available_balance=available_balance+v_contract.price_vor,reserved_balance=reserved_balance-v_contract.price_vor,updated_at=now()
 where user_id=v_contract.requester_id and currency='VOR' and reserved_balance>=v_contract.price_vor;
 if not found then raise exception 'Transport escrow is inconsistent' using errcode='23514'; end if;
 update public.player_transport_contracts set status='cancelled',updated_at=now() where id=v_contract.id;
 return jsonb_build_object('success',true,'contract_id',v_contract.id,'released_vor',v_contract.price_vor);
end;$function$


CREATE OR REPLACE FUNCTION private.complete_transport_contract(p_contract_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_contract public.player_transport_contracts%rowtype; v_requester public.wallets%rowtype; v_provider public.wallets%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_contract from public.player_transport_contracts where id=p_contract_id and provider_id=v_user for update;
 if not found or v_contract.status<>'in_transit' then raise exception 'Only the assigned transporter can complete an in-transit contract' using errcode='42501'; end if;
 perform 1 from public.wallets where user_id in(v_contract.requester_id,v_user) and currency='VOR' order by user_id for update;
 select * into v_requester from public.wallets where user_id=v_contract.requester_id and currency='VOR';
 select * into v_provider from public.wallets where user_id=v_user and currency='VOR';
 if v_requester.user_id is null or v_provider.user_id is null or v_requester.reserved_balance<v_contract.price_vor then raise exception 'Transport escrow is inconsistent' using errcode='23514'; end if;
 update public.wallets set total_balance=total_balance-v_contract.price_vor,reserved_balance=reserved_balance-v_contract.price_vor,updated_at=now() where user_id=v_contract.requester_id;
 update public.wallets set total_balance=total_balance+v_contract.price_vor,available_balance=available_balance+v_contract.price_vor,updated_at=now() where user_id=v_user;
 insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_contract.requester_id,'transport_payment',v_contract.price_vor,'VOR','completed','transport_contract',v_contract.id,'Payment for completed transport service');
 insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_user,'transport_income',v_contract.price_vor,'VOR','completed','transport_contract',v_contract.id,'Income for completed transport service');
 update public.player_transport_contracts set status='delivered',delivered_at=now(),updated_at=now() where id=v_contract.id;
 return jsonb_build_object('success',true,'contract_id',v_contract.id,'paid_vor',v_contract.price_vor,'status','delivered');
end;$function$


CREATE OR REPLACE FUNCTION private.create_inventory_sale_listing(p_item_key text, p_unit text, p_quantity numeric, p_unit_price numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_stock numeric(18,3); v_listing uuid;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if nullif(btrim(p_item_key),'') is null or nullif(btrim(p_unit),'') is null or p_quantity<=0 or p_unit_price<=0 then raise exception 'Enter a valid item, quantity and unit price' using errcode='22023'; end if;
 select quantity into v_stock from public.player_inventory where owner_id=v_user and item_key=p_item_key and unit=p_unit for update;
 if not found or v_stock<p_quantity then raise exception 'Not enough available inventory to list this quantity' using errcode='23514'; end if;
 update public.player_inventory set quantity=quantity-p_quantity,updated_at=now() where owner_id=v_user and item_key=p_item_key and unit=p_unit;
 insert into public.market_listings(owner_id,listing_type,product_name,quantity,unit_price,unit,status,created_at,updated_at)
 values(v_user,'sale',btrim(p_item_key),p_quantity,p_unit_price,btrim(p_unit),'active',now(),now()) returning id into v_listing;
 return jsonb_build_object('success',true,'listing_id',v_listing);
end;$function$


CREATE OR REPLACE FUNCTION private.create_project_rent_listing(p_project_id uuid, p_monthly_price_vor numeric, p_lease_months integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_project public.player_projects%rowtype; v_cap numeric(14,2); v_listing uuid;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if p_monthly_price_vor<=0 or p_lease_months not in(1,3) then raise exception 'Choose a valid monthly price and a 1- or 3-month lease' using errcode='22023'; end if;
 select * into v_project from public.player_projects where id=p_project_id and owner_id=v_user for update;
 if not found then raise exception 'Project not found or not owned by this player' using errcode='42501'; end if;
 if v_project.acquisition_type<>'purchase' or v_project.operating_status<>'idle' then raise exception 'Only idle projects owned outright can be offered for rent' using errcode='23514'; end if;
 if exists(select 1 from public.player_employment_contracts where project_id=p_project_id and status='active') then raise exception 'End active employment contracts before offering this project for rent' using errcode='23514'; end if;
 select max_monthly_rent_vor into v_cap from private.project_rent_price_caps where project_key=v_project.project_key;
 if v_cap is null or p_monthly_price_vor>v_cap then raise exception 'Monthly rent exceeds the site price ceiling of % VOR',v_cap using errcode='23514'; end if;
 insert into public.market_listings(owner_id,listing_type,asset_name,rent_duration,unit_price,status,project_id,lease_months,created_at,updated_at)
 values(v_user,'rent',v_project.project_key,p_lease_months||' month lease',p_monthly_price_vor,'active',p_project_id,p_lease_months,now(),now())
 returning id into v_listing;
 return jsonb_build_object('success',true,'listing_id',v_listing);
end;$function$


CREATE OR REPLACE FUNCTION private.create_transport_request(p_cargo text, p_quantity numeric, p_unit text, p_pickup text, p_delivery text, p_price_vor numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_wallet public.wallets%rowtype; v_contract uuid;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if nullif(btrim(p_cargo),'') is null or nullif(btrim(p_unit),'') is null or nullif(btrim(p_pickup),'') is null or nullif(btrim(p_delivery),'') is null or p_quantity<=0 or p_price_vor<=0 then raise exception 'Complete all transport details with valid values' using errcode='22023'; end if;
 select * into v_wallet from public.wallets where user_id=v_user and currency='VOR' for update;
 if not found or v_wallet.available_balance<p_price_vor then raise exception 'Insufficient available VOR to reserve transport payment' using errcode='23514'; end if;
 update public.wallets set available_balance=available_balance-p_price_vor,reserved_balance=reserved_balance+p_price_vor,updated_at=now() where user_id=v_user;
 insert into public.player_transport_contracts(requester_id,cargo_description,quantity,unit,pickup_location,delivery_location,price_vor)
 values(v_user,btrim(p_cargo),p_quantity,btrim(p_unit),btrim(p_pickup),btrim(p_delivery),p_price_vor) returning id into v_contract;
 return jsonb_build_object('success',true,'contract_id',v_contract,'reserved_vor',p_price_vor);
end;$function$


CREATE OR REPLACE FUNCTION private.rent_market_project(p_listing_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_listing public.market_listings%rowtype; v_source public.player_projects%rowtype; v_months integer; v_total numeric(14,2); v_buyer public.wallets%rowtype; v_owner public.wallets%rowtype; v_new_project uuid;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_listing from public.market_listings where id=p_listing_id and listing_type='rent' for update;
 if not found or v_listing.status<>'active' then raise exception 'Rental listing is no longer available' using errcode='P0002'; end if;
 if v_listing.owner_id=v_user then raise exception 'You cannot rent your own project' using errcode='42501'; end if;
 select * into v_source from public.player_projects where id=v_listing.project_id and owner_id=v_listing.owner_id for update;
 if not found or v_source.acquisition_type<>'purchase' or v_source.operating_status<>'idle' then raise exception 'The offered project is no longer available' using errcode='23514'; end if;
 if exists(select 1 from public.player_employment_contracts where project_id=v_source.id and status='active') then raise exception 'The offered project still has active workers' using errcode='23514'; end if;
 v_months:=v_listing.lease_months; v_total:=round(v_listing.unit_price*v_months,2);
 perform 1 from public.wallets where user_id in(v_user,v_listing.owner_id) and currency='VOR' order by user_id for update;
 select * into v_buyer from public.wallets where user_id=v_user and currency='VOR';
 select * into v_owner from public.wallets where user_id=v_listing.owner_id and currency='VOR';
 if v_buyer.user_id is null or v_owner.user_id is null then raise exception 'A renter or owner wallet is missing' using errcode='23514'; end if;
 if v_buyer.available_balance<v_total then raise exception 'Insufficient available VOR for the full lease' using errcode='23514'; end if;
 update public.wallets set total_balance=total_balance-v_total,available_balance=available_balance-v_total,updated_at=now() where user_id=v_user;
 update public.wallets set total_balance=total_balance+v_total,available_balance=available_balance+v_total,updated_at=now() where user_id=v_listing.owner_id;
 insert into public.player_projects(owner_id,project_key,acquisition_type,acquired_at,expires_at,operating_status,leased_from_project_id,market_listing_id)
 values(v_user,v_source.project_key,'monthly_rent',now(),now()+(v_months||' months')::interval,'idle',v_source.id,v_listing.id)
 returning id into v_new_project;
 insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_user,'project_rent_payment',v_total,'VOR','completed','market_listing',v_listing.id,'Paid player-to-player project lease');
 insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
 values(v_listing.owner_id,'project_rent_income',v_total,'VOR','completed','market_listing',v_listing.id,'Received project lease payment from another player');
 update public.market_listings set status='closed',updated_at=now() where id=v_listing.id;
 return jsonb_build_object('success',true,'project_id',v_new_project,'leased_from_project_id',v_source.id,'expires_at',now()+(v_months||' months')::interval,'total_vor',v_total);
end;$function$


CREATE OR REPLACE FUNCTION private.start_transport_contract(p_contract_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_contract public.player_transport_contracts%rowtype;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_contract from public.player_transport_contracts where id=p_contract_id and provider_id=v_user for update;
 if not found or v_contract.status<>'accepted' then raise exception 'Only the assigned transporter can start an accepted contract' using errcode='42501'; end if;
 update public.player_transport_contracts set status='in_transit',started_at=now(),updated_at=now() where id=v_contract.id;
 return jsonb_build_object('success',true,'contract_id',v_contract.id,'status','in_transit');
end;$function$


CREATE OR REPLACE FUNCTION public.accept_transport_contract(p_contract_id uuid, p_transport_project_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.accept_transport_contract(p_contract_id,p_transport_project_id); $function$


CREATE OR REPLACE FUNCTION public.buy_market_sale_listing(p_listing_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.buy_market_sale_listing(p_listing_id); $function$


CREATE OR REPLACE FUNCTION public.cancel_market_listing(p_listing_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.cancel_market_listing(p_listing_id); $function$


CREATE OR REPLACE FUNCTION public.cancel_transport_contract(p_contract_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.cancel_transport_contract(p_contract_id); $function$


CREATE OR REPLACE FUNCTION public.complete_transport_contract(p_contract_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.complete_transport_contract(p_contract_id); $function$


CREATE OR REPLACE FUNCTION public.create_inventory_sale_listing(p_item_key text, p_unit text, p_quantity numeric, p_unit_price numeric)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.create_inventory_sale_listing(p_item_key,p_unit,p_quantity,p_unit_price); $function$


CREATE OR REPLACE FUNCTION public.create_project_rent_listing(p_project_id uuid, p_monthly_price_vor numeric, p_lease_months integer)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.create_project_rent_listing(p_project_id,p_monthly_price_vor,p_lease_months); $function$


CREATE OR REPLACE FUNCTION public.create_transport_request(p_cargo text, p_quantity numeric, p_unit text, p_pickup text, p_delivery text, p_price_vor numeric)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.create_transport_request(p_cargo,p_quantity,p_unit,p_pickup,p_delivery,p_price_vor); $function$


CREATE OR REPLACE FUNCTION public.rent_market_project(p_listing_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.rent_market_project(p_listing_id); $function$


CREATE OR REPLACE FUNCTION public.start_transport_contract(p_contract_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.start_transport_contract(p_contract_id); $function$

revoke all on function public.create_inventory_sale_listing(text,text,numeric,numeric),public.buy_market_sale_listing(uuid),public.create_project_rent_listing(uuid,numeric,integer),public.rent_market_project(uuid),public.cancel_market_listing(uuid),public.create_transport_request(text,numeric,text,text,text,numeric),public.accept_transport_contract(uuid,uuid),public.start_transport_contract(uuid),public.complete_transport_contract(uuid),public.cancel_transport_contract(uuid) from public,anon;
grant execute on function public.create_inventory_sale_listing(text,text,numeric,numeric),public.buy_market_sale_listing(uuid),public.create_project_rent_listing(uuid,numeric,integer),public.rent_market_project(uuid),public.cancel_market_listing(uuid),public.create_transport_request(text,numeric,text,text,text,numeric),public.accept_transport_contract(uuid,uuid),public.start_transport_contract(uuid),public.complete_transport_contract(uuid),public.cancel_transport_contract(uuid) to authenticated;
grant usage on schema private to authenticated;
grant execute on function private.create_inventory_sale_listing(text,text,numeric,numeric),private.buy_market_sale_listing(uuid),private.create_project_rent_listing(uuid,numeric,integer),private.rent_market_project(uuid),private.cancel_market_listing(uuid),private.create_transport_request(text,numeric,text,text,text,numeric),private.accept_transport_contract(uuid,uuid),private.start_transport_contract(uuid),private.complete_transport_contract(uuid),private.cancel_transport_contract(uuid) to authenticated;