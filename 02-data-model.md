# Data model

The SQL in `supabase/migrations/` is authoritative. This doc explains intent.

| Table | Purpose |
|---|---|
| `categories` | Part categories |
| `sources` | Factories, suppliers, OEMs: where an outside number comes from |
| `parts` | One row per physical part. `sku` is the identity |
| `part_aliases` | Every outside number mapped to a part. Unique on (normalized number, source) |
| `supplier_parts` | Buying terms per part per supplier. Auto-creates an alias |
| `locations` | Storage locations, hierarchical, with scannable value |
| `stock` | Current qty per (part, location). Written only by `apply_movement()` |
| `movements` | Immutable ledger of every stock change |
| `products`, `part_fits_product` | Compatibility |

## Key behaviours
- `normalize_part_number(text)` uppercases and strips non-alphanumerics. `alias_normalized` is a generated column.
- `resolve_part_code(text)` returns candidate parts for a scanned code (SKU or alias). More than one row means ambiguity; the UI must ask.
- `apply_movement(...)` is the only write path for stock. It serializes per part, enforces no-negative stock, and is idempotent.
- Movement shapes: receive (to only), issue (from only), move (both, different), adjust (exactly one side).
- Views: `part_stock_totals` (on hand and low-stock flag).

## Flexible attributes
`parts.attributes` (JSONB) holds category-specific fields (thread size, finish, handedness). Promote a field to a real column once it is used everywhere.
