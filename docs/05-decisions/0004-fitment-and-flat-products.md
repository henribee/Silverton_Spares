# 0004: Fitment on part_fits_product; products are flat

**Status:** accepted

**Context:** Assembly letters belong to a product's instructions, not to the part. Fitment lists are incomplete and are learned late. The factory is not disciplined between models, so variants cannot be assumed to share anything.

**Decision:** `assembly_letter` lives on `part_fits_product`, optional, unique within a product. No row means unknown; a row without a letter means fits, letter unknown. Every product, including each variant, is an independent record with no parent or inheritance. A one-time "copy fitment" action eases setup of similar products.

**Why:** Matches the real data, never blocks receiving, and avoids silent inheritance that would be wrong when factory variants differ.

**Consequences:** A part that fits many products has one row per product. Commonality is recorded only by sharing a silverton_sku.
