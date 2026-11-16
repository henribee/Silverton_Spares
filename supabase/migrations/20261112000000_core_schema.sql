-- Core schema v2: silverton_sku, audit columns, fitment with assembly letters.
-- Requires Postgres 15+ (UNIQUE NULLS NOT DISTINCT, security_invoker views).
-- Stock changes ONLY through apply_movement(). See docs/02-data-model.md.
-- Project settings assumed: "Enable automatic RLS" ON, "Automatically expose new tables" OFF.
-- All Data API permissions are therefore granted explicitly at the end of this file.

-- ---------- Types ----------
create type part_status   as enum ('active', 'obsolete', 'superseded');
create type alias_type    as enum ('manufacturer', 'supplier', 'oem', 'legacy', 'barcode', 'customer', 'other');
create type movement_type as enum ('receive', 'move', 'issue', 'adjust');
create type source_kind   as enum ('manufacturer', 'supplier', 'oem', 'internal', 'other');

-- ---------- Helpers ----------
-- Uppercase and strip everything except letters and digits: 'hng-blk-m6' -> 'HNGBLKM6'
create or replace function normalize_part_number(t text)
returns text language sql immutable parallel safe as $$
  select upper(regexp_replace(coalesce(t, ''), '[^A-Za-z0-9]', '', 'g'))
$$;

create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- Uppercase + trim one text column named in the trigger argument (codes are always stored uppercase).
create or replace function upcase_column()
returns trigger language plpgsql as $$
declare
  v_col text := tg_argv[0];
  v_val text := to_jsonb(new) ->> tg_argv[0];
begin
  if v_val is not null then
    new := jsonb_populate_record(new, jsonb_build_object(v_col, upper(trim(v_val))));
  end if;
  return new;
end $$;

-- ---------- Profiles (usernames for created_by / updated_by) ----------
-- profiles.id equals the sign-in user's id. No foreign key to auth.users on purpose:
-- history must survive if a sign-in account is ever removed. Deactivate, never delete.
create table profiles (
  id          uuid primary key,
  username    text not null unique check (username ~ '^[a-z0-9._-]+$'),
  full_name   text,
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger trg_profiles_updated before update on profiles for each row execute function set_updated_at();

-- Stand-in author for imports, migrations, and service-key changes.
insert into profiles (id, username, full_name)
values ('00000000-0000-0000-0000-000000000000', 'system', 'System (imports and automated changes)');

-- 'Jane.Smith+x@company.com' -> 'jane.smith'; duplicates become jsmith2, jsmith3, ...
create or replace function generate_username(p_email text)
returns text language plpgsql as $$
declare
  v_base text;
  v_name text;
  v_n    integer := 1;
begin
  v_base := lower(split_part(split_part(coalesce(p_email, ''), '@', 1), '+', 1));
  v_base := regexp_replace(v_base, '[^a-z0-9._-]', '', 'g');
  if v_base = '' then v_base := 'user'; end if;
  v_name := v_base;
  while exists (select 1 from profiles where username = v_name) loop
    v_n := v_n + 1;
    v_name := v_base || v_n;
  end loop;
  return v_name;
end $$;

create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, username)
  values (new.id, generate_username(new.email))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- Backfill profiles for users that already exist.
do $$
declare u record;
begin
  for u in select id, email from auth.users loop
    insert into profiles (id, username) values (u.id, generate_username(u.email))
    on conflict (id) do nothing;
  end loop;
end $$;

-- The profile of the signed-in user, or 'system' when there is none (service key, SQL editor, imports).
create or replace function current_profile_id()
returns uuid language sql stable security definer set search_path = public as $$
  select coalesce((select id from profiles where id = auth.uid()),
                  '00000000-0000-0000-0000-000000000000'::uuid)
$$;

-- Stamps created_/updated_ columns. The app never sends these values.
create or replace function set_audit_columns()
returns trigger language plpgsql as $$
declare v uuid := current_profile_id();
begin
  if tg_op = 'INSERT' then
    new.created_at := now();
    new.created_by := v;
  else
    new.created_at := old.created_at;   -- cannot be altered
    new.created_by := old.created_by;
  end if;
  new.updated_at := now();
  new.updated_by := v;
  return new;
end $$;

-- ---------- Lookup tables for the silverton_sku ----------
create table categories (
  id             uuid primary key default gen_random_uuid(),
  category_code  text not null unique check (category_code ~ '^[A-Z]{3}$'),
  name           text not null unique,
  notes          text,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id)
);

create table colors (
  id          uuid primary key default gen_random_uuid(),
  color_code  text not null unique check (color_code ~ '^[A-Z0-9]{1,8}$'),
  name        text not null unique,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id)
);

create table sizes (
  id         uuid primary key default gen_random_uuid(),
  size_code  text not null unique check (size_code ~ '^[A-Z0-9]{1,8}$'),
  name       text not null unique,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id)
);

create table sources (            -- factories, suppliers, OEMs
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  kind        source_kind not null default 'supplier',
  notes       text,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id)
);

create table products (           -- each furniture product (including every variant) is its own record
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id)
);

create table locations (
  id             uuid primary key default gen_random_uuid(),
  code           text not null unique,              -- e.g. A-03-2
  name           text,
  parent_id      uuid references locations(id) on delete restrict,
  location_type  text not null default 'bin'
                 check (location_type in ('warehouse', 'zone', 'shelf', 'bin', 'other')),
  barcode_value  text not null unique,              -- value encoded in the QR label
  active         boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id)
);

-- ---------- Parts ----------
create table parts (
  id                    uuid primary key default gen_random_uuid(),
  silverton_sku         text not null unique,       -- generated by trigger; never reused or changed
  category_id           uuid not null references categories(id) on delete restrict,
  color_id              uuid not null references colors(id)     on delete restrict,
  size_id               uuid references sizes(id)               on delete restrict,   -- optional
  sku_suffix            text not null unique check (sku_suffix ~ '^[2-9A-HJKMNP-Z]{4}$'),
  name                  text not null,
  description           text,
  uom                   text not null default 'each',
  status                part_status not null default 'active',
  superseded_by_part_id uuid references parts(id),
  reorder_point         numeric(14,3) check (reorder_point >= 0),
  reorder_qty           numeric(14,3) check (reorder_qty >= 0),
  default_location_id   uuid references locations(id),
  attributes            jsonb not null default '{}'::jsonb,   -- category-specific fields
  notes                 text,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id),
  check (superseded_by_part_id is distinct from id)
);
create index parts_category_idx on parts (category_id);

-- silverton_sku = CATEGORY-COLOR[-SIZE]-SUFFIX, e.g. HNG-BLK-M6-7K4P (no size: HNG-BLK-7K4P)
-- Suffix: 4 random characters from 31 (digits 2-9, letters minus I, L, O), unique across ALL parts.
create or replace function parts_generate_sku()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  v_cat    text;
  v_color  text;
  v_size   text;
  v_suffix text;
  v_tries  integer := 0;
begin
  select category_code into v_cat   from categories where id = new.category_id;
  select color_code    into v_color from colors     where id = new.color_id;
  if new.size_id is not null then
    select size_code into v_size from sizes where id = new.size_id;
  end if;

  -- One part creation at a time: removes the check-then-insert race on the suffix.
  perform pg_advisory_xact_lock(hashtextextended('parts_sku_suffix', 0));
  loop
    v_suffix := '';
    for i in 1..4 loop
      v_suffix := v_suffix || substr(v_alphabet, 1 + floor(random() * 31)::int, 1);
    end loop;
    exit when not exists (select 1 from parts where sku_suffix = v_suffix);
    v_tries := v_tries + 1;
    if v_tries > 100 then
      raise exception 'could not generate a unique SKU suffix';
    end if;
  end loop;

  new.sku_suffix    := v_suffix;
  new.silverton_sku := v_cat || '-' || v_color || '-'
                       || case when v_size is not null then v_size || '-' else '' end
                       || v_suffix;
  return new;
end $$;

create or replace function parts_lock_identity()
returns trigger language plpgsql as $$
begin
  if new.category_id  is distinct from old.category_id
  or new.color_id     is distinct from old.color_id
  or new.size_id      is distinct from old.size_id
  or new.silverton_sku is distinct from old.silverton_sku
  or new.sku_suffix   is distinct from old.sku_suffix then
    raise exception 'category, color, size and silverton_sku cannot change after creation; retire this part and create a new one'
      using errcode = '23514';
  end if;
  return new;
end $$;

create trigger trg_parts_generate_sku  before insert on parts for each row execute function parts_generate_sku();
create trigger trg_parts_lock_identity before update on parts for each row execute function parts_lock_identity();

-- ---------- Aliases and suppliers ----------
create table part_aliases (
  id               uuid primary key default gen_random_uuid(),
  part_id          uuid not null references parts(id) on delete restrict,
  alias_number     text not null,
  alias_normalized text generated always as (normalize_part_number(alias_number)) stored,
  alias_type       alias_type not null,
  source_id        uuid references sources(id),
  verified         boolean not null default false,
  notes            text,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id),
  check (alias_normalized <> ''),
  -- same number from the same source maps to exactly one part (NULL source counts as one source)
  constraint part_aliases_number_source_key unique nulls not distinct (alias_normalized, source_id)
);
create index part_aliases_normalized_idx on part_aliases (alias_normalized);
create index part_aliases_part_idx on part_aliases (part_id);

create table supplier_parts (
  id                   uuid primary key default gen_random_uuid(),
  part_id              uuid not null references parts(id) on delete restrict,
  source_id            uuid not null references sources(id),
  supplier_part_number text not null,
  cost                 numeric(14,4) check (cost >= 0),
  currency             char(3) not null default 'USD',
  lead_time_days       integer check (lead_time_days >= 0),
  moq                  numeric(14,3) check (moq >= 0),
  pack_qty             numeric(14,3) check (pack_qty > 0),
  is_preferred         boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id),
  unique (part_id, source_id, supplier_part_number)
);
create index supplier_parts_part_idx on supplier_parts (part_id);

-- Supplier part -> alias sync (REQ-041)
create or replace function sync_supplier_alias()
returns trigger language plpgsql as $$
declare
  v_existing uuid;
begin
  select part_id into v_existing
  from part_aliases
  where alias_normalized = normalize_part_number(new.supplier_part_number)
    and source_id = new.source_id;

  if v_existing is null then
    insert into part_aliases (part_id, alias_number, alias_type, source_id, verified)
    values (new.part_id, new.supplier_part_number, 'supplier', new.source_id, true);
  elsif v_existing <> new.part_id then
    raise exception 'Supplier number % from this source is already an alias of a different part',
      new.supplier_part_number using errcode = '23505';
  end if;
  return new;
end $$;

create trigger trg_supplier_parts_alias
  after insert or update of supplier_part_number, source_id, part_id on supplier_parts
  for each row execute function sync_supplier_alias();

-- ---------- Fitment ----------
-- No row = fit unknown. Row with NULL letter = fits, letter not yet known.
-- Each product is independent; commonality is recorded only by sharing a silverton_sku.
create table part_fits_product (
  part_id         uuid not null references parts(id) on delete restrict,
  product_id      uuid not null references products(id) on delete cascade,
  assembly_letter text check (assembly_letter ~ '^[A-Z0-9]{1,2}$'),
  notes           text,
  created_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references profiles(id),
  primary key (part_id, product_id)
);
create index part_fits_product_product_idx on part_fits_product (product_id);
-- A letter identifies one part within a product's instructions.
create unique index part_fits_product_letter_key on part_fits_product (product_id, assembly_letter)
  where assembly_letter is not null;

-- One-time copy of fitment (including letters by default) onto a product that has none yet.
create or replace function copy_product_fitment(p_from uuid, p_to uuid, p_copy_letters boolean default true)
returns integer language plpgsql as $$
declare v_count integer;
begin
  if p_from = p_to then
    raise exception 'source and target product must differ' using errcode = '22023';
  end if;
  if exists (select 1 from part_fits_product where product_id = p_to) then
    raise exception 'target product already has fitment rows' using errcode = '22023';
  end if;
  insert into part_fits_product (part_id, product_id, assembly_letter, notes)
  select part_id, p_to, case when p_copy_letters then assembly_letter end, notes
  from part_fits_product where product_id = p_from;
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- ---------- Stock and ledger ----------
create table stock (
  part_id      uuid not null references parts(id) on delete restrict,
  location_id  uuid not null references locations(id) on delete restrict,
  qty          numeric(14,3) not null default 0 check (qty >= 0),
  updated_at   timestamptz not null default now(),
  updated_by   uuid not null references profiles(id),
  primary key (part_id, location_id)
);
create index stock_location_idx on stock (location_id);

create table movements (
  id               bigint generated always as identity primary key,
  part_id          uuid not null references parts(id),
  from_location_id uuid references locations(id),
  to_location_id   uuid references locations(id),
  qty              numeric(14,3) not null check (qty > 0),
  movement_type    movement_type not null,
  note             text,
  idempotency_key  text not null unique,
  created_at       timestamptz not null default now(),
  created_by       uuid not null references profiles(id),
  constraint movement_shape check (
    (movement_type = 'receive' and from_location_id is null     and to_location_id is not null) or
    (movement_type = 'issue'   and from_location_id is not null and to_location_id is null) or
    (movement_type = 'move'    and from_location_id is not null and to_location_id is not null
                               and from_location_id <> to_location_id) or
    (movement_type = 'adjust'  and (from_location_id is null) <> (to_location_id is null))
  )
);
create index movements_part_idx on movements (part_id, created_at desc);
create index movements_from_idx on movements (from_location_id);
create index movements_to_idx on movements (to_location_id);

-- ---------- Triggers: audit columns and uppercase codes ----------
do $$
declare t text;
begin
  foreach t in array array['categories','colors','sizes','sources','products','locations',
                           'parts','part_aliases','supplier_parts','part_fits_product']
  loop
    execute format('create trigger trg_%1$s_audit before insert or update on %1$I
                    for each row execute function set_audit_columns()', t);
  end loop;
end $$;

create trigger trg_categories_upcase      before insert or update on categories
  for each row execute function upcase_column('category_code');
create trigger trg_colors_upcase          before insert or update on colors
  for each row execute function upcase_column('color_code');
create trigger trg_sizes_upcase           before insert or update on sizes
  for each row execute function upcase_column('size_code');
create trigger trg_part_fits_product_upcase before insert or update on part_fits_product
  for each row execute function upcase_column('assembly_letter');

-- Placeholder color for parts where color does not apply (SKU stays 4 segments, size aside).
insert into colors (color_code, name) values ('NA', 'No color / not applicable');

-- ---------- Lookup functions (scanner) ----------
-- Returns every part matching a scanned code, by silverton_sku or alias. >1 row = ambiguous; UI must ask.
create or replace function resolve_part_code(p_code text)
returns table (part_id uuid, silverton_sku text, part_name text, match_type text,
               alias_number text, source_name text, verified boolean)
language sql stable as $$
  select p.id, p.silverton_sku, p.name, 'sku'::text, null::text, null::text, true
  from parts p
  where normalize_part_number(p.silverton_sku) = normalize_part_number(p_code)
  union all
  select p.id, p.silverton_sku, p.name, 'alias'::text, a.alias_number, s.name, a.verified
  from part_aliases a
  join parts p on p.id = a.part_id
  left join sources s on s.id = a.source_id
  where a.alias_normalized = normalize_part_number(p_code)
$$;

create or replace function resolve_location_code(p_code text)
returns setof locations
language sql stable as $$
  select * from locations
  where active and (barcode_value = p_code or upper(code) = upper(p_code))
$$;

-- ---------- The only write path for stock ----------
create or replace function apply_movement(
  p_part_id          uuid,
  p_from             uuid,
  p_to               uuid,
  p_qty              numeric,
  p_type             movement_type,
  p_idempotency_key  text,
  p_note             text default null
) returns movements
language plpgsql security definer set search_path = public as $$
declare
  v_existing movements;
  v_new      movements;
  v_rows     integer;
  v_user     uuid := current_profile_id();
begin
  if p_idempotency_key is null or length(trim(p_idempotency_key)) = 0 then
    raise exception 'idempotency key is required' using errcode = '22023';
  end if;
  if p_type = 'adjust' and (p_note is null or length(trim(p_note)) = 0) then
    raise exception 'a note is required for adjustments' using errcode = '22023';
  end if;

  -- Serialize all movements of one part: avoids races and deadlocks.
  perform pg_advisory_xact_lock(hashtextextended(p_part_id::text, 0));

  -- Retry of an already-applied request: return the original result.
  select * into v_existing from movements where idempotency_key = p_idempotency_key;
  if found then
    return v_existing;
  end if;

  -- Insert first: the movement_shape check rejects malformed requests early.
  insert into movements (part_id, from_location_id, to_location_id, qty, movement_type,
                         note, idempotency_key, created_by)
  values (p_part_id, p_from, p_to, p_qty, p_type, p_note, p_idempotency_key, v_user)
  returning * into v_new;

  if p_from is not null then
    update stock
       set qty = qty - p_qty, updated_at = now(), updated_by = v_user
     where part_id = p_part_id and location_id = p_from and qty >= p_qty;
    get diagnostics v_rows = row_count;
    if v_rows = 0 then
      raise exception 'Insufficient stock at source location'
        using errcode = 'P0001', hint = 'Check the current quantity and try again';
    end if;
  end if;

  if p_to is not null then
    insert into stock (part_id, location_id, qty, updated_by)
    values (p_part_id, p_to, p_qty, v_user)
    on conflict (part_id, location_id)
    do update set qty = stock.qty + excluded.qty, updated_at = now(), updated_by = v_user;
  end if;

  return v_new;
end $$;

-- ---------- Views ----------
create view part_stock_totals with (security_invoker = true) as
select p.id as part_id, p.silverton_sku, p.name,
       coalesce(sum(s.qty), 0) as on_hand,
       p.reorder_point,
       (p.reorder_point is not null and coalesce(sum(s.qty), 0) <= p.reorder_point) as is_low
from parts p
left join stock s on s.part_id = p.id
where p.status = 'active'
group by p.id;

-- "In product X, which part is letter B?" and "which products use this part?"
create view v_product_parts with (security_invoker = true) as
select pr.id as product_id, pr.code as product_code, pr.name as product_name,
       pf.assembly_letter,
       p.id as part_id, p.silverton_sku, p.name as part_name, p.status
from part_fits_product pf
join products pr on pr.id = pf.product_id
join parts p     on p.id  = pf.part_id;

-- ---------- Row-level security (REQ-081) ----------
-- Starter policy: signed-in users can read everything and edit catalog data.
-- Tighten with roles later (REQ-071). stock and movements are read-only to clients.
do $$
declare t text;
begin
  foreach t in array array['profiles','categories','colors','sizes','sources','products','locations',
                           'parts','part_aliases','supplier_parts','part_fits_product','stock','movements']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "read %1$s" on %1$I for select to authenticated using (true)', t);
  end loop;

  foreach t in array array['categories','colors','sizes','sources','products','locations',
                           'parts','part_aliases','supplier_parts','part_fits_product']
  loop
    execute format('create policy "write %1$s" on %1$I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

create policy "update own profile" on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ---------- Explicit Data API permissions ----------
revoke all on all tables    in schema public from anon;
revoke all on all sequences in schema public from anon;

grant usage on schema public to authenticated;
grant select, insert, update, delete on
  categories, colors, sizes, sources, products, locations,
  parts, part_aliases, supplier_parts, part_fits_product
  to authenticated;
grant select on profiles, stock, movements, part_stock_totals, v_product_parts to authenticated;
grant update (username, full_name) on profiles to authenticated;

revoke execute on function apply_movement(uuid, uuid, uuid, numeric, movement_type, text, text) from public, anon;
revoke execute on function handle_new_user(), parts_generate_sku() from public, anon;
grant execute on function
  apply_movement(uuid, uuid, uuid, numeric, movement_type, text, text),
  resolve_part_code(text), resolve_location_code(text),
  copy_product_fitment(uuid, uuid, boolean),
  current_profile_id(), normalize_part_number(text)
  to authenticated;
