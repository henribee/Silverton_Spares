# Data model

The SQL in `supabase/migrations/` is authoritative. This doc explains intent.

| Table | Purpose |
|---|---|
| `profiles` | One per user: unique username (from email), active flag. Includes a `system` profile |
| `categories` | 3-letter `category_code` (first segment of the SKU) |
| `colors` | `color_code` (second segment). Exactly 3 characters. Includes `NON` for "no color" |
| `sizes` | `size_code` (optional third segment, exactly 1 character) |
| `sources` | Factories, suppliers, OEMs: where an outside number comes from |
| `parts` | One row per physical part. `silverton_sku` is the identity |
| `part_aliases` | Every outside number mapped to a part. Unique on (normalized number, source) |
| `supplier_parts` | Buying terms per part per supplier. Auto-creates an alias |
| `products` | Furniture products. Each variant is its own independent record |
| `part_fits_product` | Which products a part fits, plus the optional `assembly_letter` |
| `locations` | Storage locations, hierarchical, with scannable value |
| `stock` | Current qty per (part, location). Written only by `apply_movement()` |
| `movements` | Immutable ledger of every stock change |

## silverton_sku
`CATEGORY-COLOR[-SIZE]-SUFFIX`, built by a trigger on insert: `HNG-BLK-M-7K4P`, or `HNG-BLK-7K4P` with no size.
- Suffix: 4 random characters from `23456789ABCDEFGHJKMNPQRSTUVWXYZ` (31 characters, about 923,000 combinations), unique across all parts, retried on collision.
- Category, color, size, and SKU are locked after creation. Fix mistakes by retiring the part and creating a new one.
- Codes are uppercased automatically. Constraints: category exactly 3 letters; color exactly 3 letters or digits; size exactly 1 letter or digit.

## Fitment states (`part_fits_product`)
| State | Meaning |
|---|---|
| no row | fit unknown |
| row, `assembly_letter` null | fits, letter not yet known |
| row with letter | known fit and letter |

The letter (1 or 2 letters/digits, stored uppercase) is unique within a product, and may repeat across products. Products never inherit from each other; `copy_product_fitment(from, to)` is a one-time copy onto a product with no fitment. View `v_product_parts` answers "which part is letter B in product X" and "which products use this part".

## Audit columns
- Catalog tables: `created_at`, `created_by`, `updated_at`, `updated_by` (references `profiles`). Triggers set them; `created_*` cannot be altered.
- `movements`: `created_by`, `created_at`. `stock`: `updated_by`, `updated_at` (set by `apply_movement()`).
- With no signed-in user (service key, SQL editor, imports) the author is the `system` profile.
- A profile is created automatically when a user is added to Supabase Auth. Username = email text before `@`, lowercased, `+tag` and invalid characters removed; duplicates become `name2`, `name3`.

## Key behaviours
- `normalize_part_number(text)` uppercases and strips non-alphanumerics. `alias_normalized` is a generated column.
- `resolve_part_code(text)` returns candidate parts for a scanned code (silverton_sku or alias). More than one row means ambiguity; the UI must ask.
- `apply_movement(...)` is the only write path for stock. It serializes per part, enforces no-negative stock, and is idempotent.
- Movement shapes: receive (to only), issue (from only), move (both, different), adjust (exactly one side, note required).
- Views: `part_stock_totals` (on hand and low-stock flag), `v_product_parts`.

## Permissions
Row-level security is on for every table. The project does not auto-expose tables, so the migration grants access explicitly: signed-in users read everything and edit catalog tables; `stock` and `movements` are read-only to clients; the anonymous role has no access.

## Flexible attributes
`parts.attributes` (JSONB) holds category-specific fields (thread size, finish, handedness). Promote a field to a real column once it is used everywhere.
