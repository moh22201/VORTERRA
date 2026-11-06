create or replace function private.settle_due_production_cycles()
returns jsonb language plpgsql security definer set search_path=''
as $fn$
declare v_user uuid:=auth.uid(); v_cycle record; v_count integer:=0;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 for v_cycle in
  select id from public.production_cycles
   where owner_id=v_user and status='running' and completes_at<=now()
   order by completes_at
   for update skip locked
 loop
  perform private.complete_project_production(v_cycle.id);
  v_count:=v_count+1;
 end loop;
 return jsonb_build_object('success',true,'settled_cycles',v_count);
end;$fn$;
create or replace function public.settle_due_production_cycles()
returns jsonb language sql security invoker set search_path=''
as $fn$ select private.settle_due_production_cycles(); $fn$;
revoke all on function public.settle_due_production_cycles() from public,anon;
grant execute on function public.settle_due_production_cycles() to authenticated;
grant execute on function private.settle_due_production_cycles() to authenticated;