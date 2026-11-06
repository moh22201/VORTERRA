revoke all on table public.player_employment_contracts from anon;
grant select on table public.player_employment_contracts to authenticated;
revoke insert, update, delete on table public.player_employment_contracts from anon, authenticated;
