# 0002: Separate `part_aliases` and `supplier_parts`

**Status:** accepted

**Context:** The factory renumbers identical parts. We must identify parts from any number, and we must also track buying terms.

**Decision:** `part_aliases` answers "what is this number?" (identification). `supplier_parts` answers "who sells it and on what terms?" (purchasing). A trigger creates the alias when a supplier part is saved.

**Why:** Most aliases have no commercial meaning (old factory numbers on existing stock). Mixing them clutters both concerns.

**Consequences:** Alias uniqueness is on (normalized number, source). Conflicting alias to a different part raises an error.
