-- Delta contract for pull_dog_delta (dogs + memberships only).

create extension if not exists pgcrypto;

-- pull_dog_delta CONTRACT
-- -----------------------
-- Access control:
--   - Caller MUST have membership on the dog (dog_memberships).
--   - If not a member: function raises exception 'forbidden'.
--
-- Return value (on success):
--   JSONB object with the following shape:
--   {
--     "server_time": <ISO-8601 timestamp when server processed the request>,
--     "dog_id": <uuid>,
--     "since": <ISO-8601 timestamp, echo of input>,
--     "dogs": [ <dogs rows where updated_at > since> ],
--     "memberships": [ <dog_memberships rows where updated_at > since> ]
--   }
--
-- Notes:
--   - Tombstones (is_deleted = true) are returned as regular rows.
--   - Deterministic ordering is enforced for stable client-side sync.
--   - This function is intentionally strict; forbidden access raises exception.
create or replace function pull_dog_delta(p_dog_id uuid, p_since timestamptz)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_server_time timestamptz := now();
begin
  if not exists (
    select 1
    from dog_memberships m
    where m.dog_id = p_dog_id
      and m.user_id = auth.uid()
  ) then
    raise exception 'forbidden' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'server_time', v_server_time,
    'dog_id', p_dog_id,
    'since', p_since,
    'dogs', (
      select coalesce(jsonb_agg(to_jsonb(d) order by d.updated_at asc, d.id asc), '[]'::jsonb)
      from dogs d
      where d.id = p_dog_id
        and d.updated_at > p_since
    ),
    'memberships', (
      select coalesce(jsonb_agg(to_jsonb(m) order by m.updated_at asc, m.user_id asc), '[]'::jsonb)
      from dog_memberships m
      where m.dog_id = p_dog_id
        and m.updated_at > p_since
    )
  );
end;
$$;
