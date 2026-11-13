# CLAUDE.md

Entry point for AI coding tools. Keep this under one page. Details live in `/docs`.

## What this is
Inventory system for **furniture spare parts**. Staff use a phone or a barcode scanner to scan parts into, out of, and between storage locations. The factory often puts different part numbers on identical parts, so every outside number maps to one local SKU (silverton_sku).

## Stack
- Database: Supabase (Postgres 15+). Schema lives in `supabase/migrations/`.
- Frontend: PWA (camera barcode scanning) built and hosted on Cloudflare, in `/app`.
- Scanning library: ZXing-js or html5-qrcode (iOS Safari has no BarcodeDetector).

## Read first
1. `docs/00-overview.md` scope and non-goals
2. `docs/01-requirements.md` numbered requirements (REQ-xxx)
3. `docs/02-data-model.md` and the migration SQL (the SQL is authoritative)
4. `docs/03-process-flows.md` scan flows
5. `docs/04-glossary.md`, `docs/05-decisions/`, `docs/06-open-questions.md`

## Hard rules
- **Stock changes only through `apply_movement()`.** Never update `stock` or insert into `movements` directly.
- Every movement carries a client-generated **idempotency key** (UUID). Retries must be safe.
- **Never delete parts.** Set `status` to `obsolete` or `superseded`.
- The SKU is the identity. Outside numbers go in `part_aliases`; purchasing terms go in `supplier_parts`.
- Compare part numbers using `normalize_part_number()`, never raw text.
- Schema changes are **migration files only**, never dashboard edits. Add RLS policies in the same migration as any new table.
- No secrets in the repo. Env var names are listed in the README; values live in Supabase and Cloudflare.
- If a requirement is unclear, check `docs/06-open-questions.md` and ask rather than guess.

## Working style
- Work in small slices: "implement REQ-032 using docs/03 and the migration."
- Update docs in the same commit as the code change.
- Add tests that reference REQ ids (movement function, alias lookup, scan flows).
