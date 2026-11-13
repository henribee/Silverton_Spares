# Silverton_Spares
Spares Inventory Management System
# Spare Parts Inventory

Phone-scanned and barcode reader-scanned inventory for furniture spare parts. See `CLAUDE.md` and `/docs`.

## Setup
1. Install the Supabase CLI and link the project: `supabase link --project-ref <ref>`
2. Apply the schema: `supabase db push`
3. Load seed CSVs from `supabase/seed/` (import order in its README)

## Environment variables (names only, never values)
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (frontend; safe to expose, protected by RLS)
- `SUPABASE_SERVICE_ROLE_KEY` (server/import scripts only; never in the frontend)

Set values in Supabase and Cloudflare, not in this repo.
