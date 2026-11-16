-- Security Advisor follow-up (warnings, not errors). Safe to apply on top of the core schema.

-- 1. Pin search_path on helper functions ("function search path mutable").
alter function normalize_part_number(text)               set search_path = public;
alter function set_updated_at()                          set search_path = public;
alter function upcase_column()                           set search_path = public;
alter function generate_username(text)                   set search_path = public;
alter function set_audit_columns()                       set search_path = public;
alter function parts_lock_identity()                     set search_path = public;
alter function sync_supplier_alias()                     set search_path = public;
alter function copy_product_fitment(uuid, uuid, boolean) set search_path = public;
alter function resolve_part_code(text)                   set search_path = public;
alter function resolve_location_code(text)               set search_path = public;

-- 2. Trigger-only SECURITY DEFINER functions must not be callable through the API.
--    (Triggers still fire normally; no EXECUTE check happens when a trigger runs.)
revoke execute on function handle_new_user(), parts_generate_sku() from public, anon, authenticated;

-- 3. current_profile_id() is needed by signed-in users only.
revoke execute on function current_profile_id() from public, anon;
grant  execute on function current_profile_id() to authenticated;
