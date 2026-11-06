alter table public.production_cycles add column if not exists wage_payments jsonb not null default '[]'::jsonb;
create unique index if not exists player_employment_one_active_contract_per_project on public.player_employment_contracts(worker_id,project_id) where status='active' and project_id is not null;
CREATE OR REPLACE FUNCTION private.cancel_project_production(p_cycle_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_user uuid:=auth.uid(); v_cycle public.production_cycles%rowtype; v_item jsonb;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_cycle from public.production_cycles where id=p_cycle_id and owner_id=v_user for update;
 if not found then raise exception 'Production cycle not found' using errcode='42501'; end if;
 if v_cycle.status<>'running' then raise exception 'Production cycle is not running' using errcode='23514'; end if;
 if now()>=v_cycle.completes_at then raise exception 'The shift has finished and must be settled, not cancelled' using errcode='23514'; end if;
 update public.wallets set available_balance=available_balance+v_cycle.reserved_total_vor,reserved_balance=reserved_balance-v_cycle.reserved_total_vor,updated_at=now()
 where user_id=v_user and currency='VOR' and reserved_balance>=v_cycle.reserved_total_vor;
 if not found then raise exception 'Reserved production funds are inconsistent' using errcode='23514'; end if;
 for v_item in select value from jsonb_array_elements(v_cycle.input_items) loop
  insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at)
  values(v_user,v_item->>'item',v_item->>'unit',(v_item->>'quantity')::numeric,now())
  on conflict(owner_id,item_key,unit) do update set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
 end loop;
 update public.production_cycles set status='cancelled',completed_at=now() where id=v_cycle.id;
 update public.player_projects set operating_status='idle',updated_at=now() where id=v_cycle.project_id and owner_id=v_user;
 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'released_vor',v_cycle.reserved_total_vor);
end;$function$


CREATE OR REPLACE FUNCTION private.complete_project_production(p_cycle_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_user uuid:=auth.uid(); v_cycle public.production_cycles%rowtype; v_item jsonb; v_payment jsonb; v_outputs integer:=0;
 v_worker uuid; v_wage numeric(14,2);
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
 if v_cycle.wage_total_vor>0 then
  insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
  values(v_user,'production_wage',v_cycle.wage_total_vor,'VOR','completed','production_cycle',v_cycle.id,'Worker wages for completed 8-hour production shift');
 end if;
 if v_cycle.operating_cost_vor>0 then
  insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
  values(v_user,'production_cost',v_cycle.operating_cost_vor,'VOR','completed','production_cycle',v_cycle.id,'Operating costs for completed 8-hour production shift');
 end if;
 for v_payment in select value from jsonb_array_elements(v_cycle.wage_payments) loop
  v_worker:=(v_payment->>'worker_id')::uuid; v_wage:=(v_payment->>'wage')::numeric(14,2);
  if v_wage>0 then
   insert into public.wallets(user_id,currency,total_balance,available_balance,reserved_balance)
   values(v_worker,'VOR',v_wage,v_wage,0)
   on conflict(user_id) do update set total_balance=public.wallets.total_balance+excluded.total_balance,
    available_balance=public.wallets.available_balance+excluded.available_balance,updated_at=now();
   insert into public.wallet_transactions(user_id,transaction_type,amount,currency,status,reference_type,reference_id,description)
   values(v_worker,'wage_income',v_wage,'VOR','completed','production_cycle',v_cycle.id,'Wages received for an 8-hour production shift');
  end if;
 end loop;
 for v_item in select value from jsonb_array_elements(v_cycle.output_items) loop
  insert into public.player_inventory(owner_id,item_key,unit,quantity,updated_at) values(v_user,v_item->>'item',v_item->>'unit',(v_item->>'quantity')::numeric,now())
  on conflict(owner_id,item_key,unit) do update set quantity=public.player_inventory.quantity+excluded.quantity,updated_at=now();
  v_outputs:=v_outputs+1;
 end loop;
 update public.production_cycles set status='completed',completed_at=now() where id=v_cycle.id;
 update public.player_projects set operating_status='idle',updated_at=now() where id=v_cycle.project_id and owner_id=v_user;
 return jsonb_build_object('success',true,'cycle_id',v_cycle.id,'outputs_created',v_outputs,'wages_paid_vor',v_cycle.wage_total_vor,'operating_cost_vor',v_cycle.operating_cost_vor);
end;$function$


CREATE OR REPLACE FUNCTION private.start_project_production(p_project_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_user uuid:=auth.uid(); v_project public.player_projects%rowtype; v_rule private.project_production_rules%rowtype;
 v_workers integer; v_wages numeric(14,2); v_payments jsonb; v_reserve numeric(14,2); v_wallet public.wallets%rowtype;
 v_item jsonb; v_stock numeric(18,3); v_cycle uuid;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_project from public.player_projects where id=p_project_id and owner_id=v_user for update;
 if not found then raise exception 'Project not found or not owned by this player' using errcode='42501'; end if;
 if v_project.operating_status not in('idle','awaiting_clearance') then raise exception 'Project is not idle' using errcode='23514'; end if;
 if v_project.acquisition_type='monthly_rent' and v_project.expires_at<=now() then raise exception 'Project lease has expired' using errcode='23514'; end if;
 select * into v_rule from private.project_production_rules where project_key=v_project.project_key and enabled;
 if not found then raise exception 'This project does not have a production cycle' using errcode='22023'; end if;
 select count(*)::integer,coalesce(sum(wage_per_shift),0)::numeric(14,2),
        coalesce(jsonb_agg(jsonb_build_object('worker_id',worker_id,'wage',wage_per_shift)),'[]'::jsonb)
 into v_workers,v_wages,v_payments
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
 insert into public.production_cycles(owner_id,project_id,project_key,worker_count,wage_total_vor,operating_cost_vor,reserved_total_vor,output_items,input_items,wage_payments,started_at,completes_at)
 values(v_user,p_project_id,v_project.project_key,v_workers,v_wages,v_rule.operating_cost_vor,v_reserve,v_rule.output_items,v_rule.input_items,v_payments,now(),now()+interval '8 hours') returning id into v_cycle;
 update public.player_projects set operating_status='running',updated_at=now() where id=p_project_id;
 return jsonb_build_object('success',true,'cycle_id',v_cycle,'worker_count',v_workers,'wage_total_vor',v_wages,'operating_cost_vor',v_rule.operating_cost_vor,'reserved_total_vor',v_reserve,'completes_at',now()+interval '8 hours');
end;$function$
