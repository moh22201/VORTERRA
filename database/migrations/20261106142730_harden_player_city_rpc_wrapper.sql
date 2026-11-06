-- Keep the implementation private and expose only an invoker wrapper.
create or replace function private.create_player_city_and_assign_assets(
  p_city_name text,
  p_terrain_type text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_city_id uuid;
  v_assigned integer := 0;
begin
  if v_user is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  if nullif(btrim(p_city_name), '') is null or length(btrim(p_city_name)) > 80 then
    raise exception 'City name must contain 1 to 80 characters' using errcode = '22023';
  end if;
  if p_terrain_type not in ('coastal', 'inland', 'desert') then
    raise exception 'Invalid city terrain' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user::text || ':player-city', 0));
  select id into v_city_id from public.player_cities where owner_id = v_user order by created_at limit 1 for update;
  if v_city_id is not null then raise exception 'A game city is already registered for this account' using errcode = '23505'; end if;
  insert into public.player_cities(owner_id, city_name, terrain_type, is_coastal)
  values (v_user, btrim(p_city_name), p_terrain_type, p_terrain_type = 'coastal')
  returning id into v_city_id;
  update public.player_projects set city_id = v_city_id, updated_at = now()
  where owner_id = v_user and city_id is null
    and (acquisition_type = 'purchase' or (acquisition_type = 'monthly_rent' and expires_at > now()));
  get diagnostics v_assigned = row_count;
  return jsonb_build_object('success', true, 'city_id', v_city_id, 'city_name', btrim(p_city_name),
    'terrain_type', p_terrain_type, 'assigned_properties', v_assigned);
end;
$function$;
revoke all on function private.create_player_city_and_assign_assets(text, text) from public, anon;
grant execute on function private.create_player_city_and_assign_assets(text, text) to authenticated;
create or replace function public.create_player_city_and_assign_assets(
  p_city_name text,
  p_terrain_type text
)
returns jsonb
language sql
set search_path = ''
as $function$
  select private.create_player_city_and_assign_assets(p_city_name, p_terrain_type);
$function$;
revoke all on function public.create_player_city_and_assign_assets(text, text) from public, anon;
grant execute on function public.create_player_city_and_assign_assets(text, text) to authenticated;
