revoke all on function private.start_worker_shift(uuid,uuid,timestamptz) from public,anon,authenticated;
revoke all on function private.pause_worker_shift(uuid,timestamptz,boolean) from public,anon,authenticated;
revoke all on function private.handle_employment_shift_change() from public,anon,authenticated;

revoke all on function private.start_project_production(uuid) from public,anon,authenticated;
revoke all on function private.complete_project_production(uuid) from public,anon,authenticated;
revoke all on function private.cancel_project_production(uuid) from public,anon,authenticated;

grant execute on function private.start_project_production(uuid) to authenticated;
grant execute on function private.complete_project_production(uuid) to authenticated;
grant execute on function private.cancel_project_production(uuid) to authenticated;
