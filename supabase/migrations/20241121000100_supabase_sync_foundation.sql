-- Supabase sync foundation for Jakthund (schema + RLS + RPC).

-- Extensions
create extension if not exists pgcrypto;

-- Enums
create type dog_role as enum ('owner', 'editor', 'viewer');
create type transfer_status as enum ('pending', 'accepted', 'cancelled', 'expired');

-- Tables
create table if not exists dogs (
  id uuid primary key default gen_random_uuid(),
  dog_key text not null unique,
  name text not null,
  reg_nr_display text,
  image_path text,
  birth_date date,
  pedigree_url text,
  breed text,
  owner_user_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  client_updated_at timestamptz,
  client_id text,
  client_op_id text
);

create table if not exists dog_memberships (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references dogs(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  role dog_role not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  client_updated_at timestamptz,
  client_id text,
  client_op_id text
);

create table if not exists invites (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references dogs(id) on delete cascade,
  role dog_role not null,
  token_hash text not null unique,
  expires_at timestamptz not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  client_updated_at timestamptz,
  client_id text,
  client_op_id text
);

create table if not exists ownership_transfers (
  id uuid primary key default gen_random_uuid(),
  dog_id uuid not null references dogs(id) on delete cascade,
  from_user_id uuid not null references auth.users(id),
  to_user_id uuid not null references auth.users(id),
  token_hash text not null unique,
  status transfer_status not null default 'pending',
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  client_updated_at timestamptz,
  client_id text,
  client_op_id text
);

create table if not exists sync_receipts (
  id uuid primary key default gen_random_uuid(),
  client_id text not null,
  client_op_id text not null,
  created_at timestamptz not null default now()
);

create unique index if not exists sync_receipts_unique
  on sync_receipts(client_id, client_op_id);

-- Uniqueness constraints
create unique index if not exists dog_memberships_unique_user
  on dog_memberships(dog_id, user_id)
  where is_deleted = false;

-- Only one owner membership per dog.
create unique index if not exists dog_memberships_one_owner
  on dog_memberships(dog_id)
  where role = 'owner' and is_deleted = false;

-- RLS
alter table dogs enable row level security;
alter table dog_memberships enable row level security;
alter table invites enable row level security;
alter table ownership_transfers enable row level security;

-- Policies
-- Dogs: members can read, only owner can update.
create policy dogs_select_for_members
  on dogs for select
  using (
    owner_user_id = auth.uid()
    or exists (
      select 1 from dog_memberships m
      where m.dog_id = dogs.id
        and m.user_id = auth.uid()
        and m.is_deleted = false
    )
  );

create policy dogs_update_owner_only
  on dogs for update
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

-- Memberships: members can read; only owner can write.
create policy memberships_select_for_members
  on dog_memberships for select
  using (
    exists (
      select 1 from dog_memberships m
      where m.dog_id = dog_memberships.dog_id
        and m.user_id = auth.uid()
        and m.is_deleted = false
    )
  );

create policy memberships_owner_insert
  on dog_memberships for insert
  with check (
    exists (
      select 1 from dogs d
      where d.id = dog_memberships.dog_id
        and d.owner_user_id = auth.uid()
    )
  );

create policy memberships_owner_update
  on dog_memberships for update
  using (
    exists (
      select 1 from dogs d
      where d.id = dog_memberships.dog_id
        and d.owner_user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from dogs d
      where d.id = dog_memberships.dog_id
        and d.owner_user_id = auth.uid()
    )
  );

create policy memberships_owner_delete
  on dog_memberships for delete
  using (
    exists (
      select 1 from dogs d
      where d.id = dog_memberships.dog_id
        and d.owner_user_id = auth.uid()
    )
  );

-- Invites: owner can read/write.
create policy invites_owner_all
  on invites for all
  using (
    exists (
      select 1 from dogs d
      where d.id = invites.dog_id
        and d.owner_user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from dogs d
      where d.id = invites.dog_id
        and d.owner_user_id = auth.uid()
    )
  );

-- Transfers: owner can insert/update; sender/recipient can read.
create policy transfers_select_parties
  on ownership_transfers for select
  using (from_user_id = auth.uid() or to_user_id = auth.uid());

create policy transfers_owner_insert
  on ownership_transfers for insert
  with check (
    exists (
      select 1 from dogs d
      where d.id = ownership_transfers.dog_id
        and d.owner_user_id = auth.uid()
    )
  );

create policy transfers_owner_update
  on ownership_transfers for update
  using (
    exists (
      select 1 from dogs d
      where d.id = ownership_transfers.dog_id
        and d.owner_user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from dogs d
      where d.id = ownership_transfers.dog_id
        and d.owner_user_id = auth.uid()
    )
  );

-- RPC: pull all changes since timestamp for a dog, including tombstones.
create or replace function pull_dog_delta(p_dog_id uuid, p_since timestamptz)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_server_time timestamptz := now();
begin
  return jsonb_build_object(
    'server_time', v_server_time,
    'dogs', (
      select coalesce(jsonb_agg(to_jsonb(d)), '[]'::jsonb)
      from dogs d
      where d.id = p_dog_id
        and (d.updated_at > p_since or d.is_deleted = true)
    ),
    'memberships', (
      select coalesce(jsonb_agg(to_jsonb(m)), '[]'::jsonb)
      from dog_memberships m
      where m.dog_id = p_dog_id
        and (m.updated_at > p_since or m.is_deleted = true)
    )
  );
end;
$$;

-- RPC: push client batch with idempotency. Uses invoker permissions (RLS applies).
create or replace function push_batch(p_changes jsonb, p_client_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception 'push_batch_not_implemented' using errcode = 'P0001';
end;
$$;

-- RPC: accept invite by token. Stores only token_hash.
create or replace function accept_invite(raw_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite invites%rowtype;
begin
  select * into v_invite
  from invites
  where token_hash = crypt(raw_token, token_hash)
    and is_deleted = false
  for update;

  if not found then
    raise exception 'invite_not_found' using errcode = 'P0001';
  end if;

  if v_invite.status <> 'pending' then
    raise exception 'invite_inactive' using errcode = 'P0001';
  end if;

  if v_invite.expires_at <= now() then
    update invites
      set status = 'expired', updated_at = now(), updated_by = auth.uid()
      where id = v_invite.id;
    raise exception 'invite_expired' using errcode = 'P0001';
  end if;

  insert into dog_memberships (
    dog_id,
    user_id,
    role,
    status,
    created_at,
    updated_at,
    updated_by
  )
  values (
    v_invite.dog_id,
    auth.uid(),
    v_invite.role,
    'active',
    now(),
    now(),
    auth.uid()
  )
  on conflict do nothing;

  update invites
    set status = 'accepted', updated_at = now(), updated_by = auth.uid()
    where id = v_invite.id;

  return v_invite.dog_id;
end;
$$;

-- RPC: accept transfer by token. Stores only token_hash.
create or replace function accept_transfer(raw_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_transfer ownership_transfers%rowtype;
begin
  select * into v_transfer
  from ownership_transfers
  where token_hash = crypt(raw_token, token_hash)
    and is_deleted = false
  for update;

  if not found then
    raise exception 'transfer_not_found' using errcode = 'P0001';
  end if;

  if v_transfer.status <> 'pending' then
    raise exception 'transfer_inactive' using errcode = 'P0001';
  end if;

  if v_transfer.expires_at <= now() then
    update ownership_transfers
      set status = 'expired', updated_at = now(), updated_by = auth.uid()
      where id = v_transfer.id;
    raise exception 'transfer_expired' using errcode = 'P0001';
  end if;

  if v_transfer.to_user_id <> auth.uid() then
    raise exception 'transfer_not_recipient' using errcode = 'P0001';
  end if;

  update dogs
    set owner_user_id = v_transfer.to_user_id,
        updated_at = now(),
        updated_by = auth.uid()
    where id = v_transfer.dog_id;

  insert into dog_memberships (
    dog_id,
    user_id,
    role,
    status,
    created_at,
    updated_at,
    updated_by
  )
  values (
    v_transfer.dog_id,
    v_transfer.to_user_id,
    'owner',
    'active',
    now(),
    now(),
    auth.uid()
  )
  on conflict do nothing;

  update dog_memberships
    set role = 'editor', status = 'active', updated_at = now(), updated_by = auth.uid()
    where dog_id = v_transfer.dog_id
      and user_id = v_transfer.from_user_id
      and is_deleted = false;

  update ownership_transfers
    set status = 'accepted', updated_at = now(), updated_by = auth.uid()
    where id = v_transfer.id;

  return v_transfer.dog_id;
end;
$$;
