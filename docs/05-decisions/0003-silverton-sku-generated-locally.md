# 0003: silverton_sku generated locally by the database

**Status:** accepted

**Context:** The factory puts different part numbers on identical parts, even across models, and cannot keep its data consistent. We need a stable identity for fulfillment.

**Decision:** Our own `silverton_sku` = category code + color code + optional size code + 4-character random suffix, built by a database trigger on insert. Category, color, size, and SKU are locked after creation.

**Why:** Human-readable, scannable, independent of factory data, and never changes. The random suffix is unique across all parts, so a SKU is unambiguous even when two parts share category, color, and size. Ambiguous characters (0, O, 1, I, L) are excluded from the suffix.

**Consequences:** A part created with the wrong color or size is retired and recreated (the merge feature moves aliases and stock). Factory numbers live only in `part_aliases`.
