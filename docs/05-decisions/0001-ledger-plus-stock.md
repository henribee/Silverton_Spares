# 0001: Movement ledger plus stock table

**Status:** accepted

**Context:** We need correct levels, an audit trail, and fast reads.

**Decision:** Record every change as an immutable row in `movements` and keep `stock` (part x location) updated in the same transaction by `apply_movement()`. Direct writes are blocked.

**Why:** Instant current levels, full history, ability to rebuild stock from movements, and safe retries via idempotency keys.

**Consequences:** All writes go through one function; corrections are new adjust movements, never edits.
