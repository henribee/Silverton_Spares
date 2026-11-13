# Process flows

## 1. Scan flow (Receive / Move / Issue)
```mermaid
flowchart TD
  A["Pick mode: Receive, Move, Issue"] --> B["Scan location label"]
  B --> C{"Location found?"}
  C -- no --> C1["Error: unknown location"] --> B
  C -- yes --> D["Scan part code"]
  D --> E["resolve_part_code"]
  E --> F{"Matches"}
  F -- "0" --> U["Unknown code flow"]
  F -- "1" --> G["Show part, photo, current qty"]
  F -- "2 or more" --> H["Ask user to choose part"] --> G
  G --> I["Confirm quantity, default 1"]
  I --> J["Move needs destination: scan second location"]
  J --> K["apply_movement with new idempotency key"]
  I --> K
  K --> L{"Success?"}
  L -- yes --> M["Confirmation, ready for next scan"] --> D
  L -- "insufficient stock" --> N["Show error with current qty"] --> I
```
Notes: in Receive the scanned location is the destination; in Issue it is the source; in Move it is the source and a second scan sets the destination.

## 2. Unknown code
```mermaid
flowchart TD
  U["Code not found"] --> Q{"Link or create?"}
  Q -- "Link to existing" --> S["Search by SKU, name, photo"] --> P["Choose part"] --> V["Add alias, verified = false, source selected"]
  Q -- "Create new" --> N["Enter SKU, name, category, UoM"] --> W["Save part and alias"]
  V --> R["Return to scan flow with the part"]
  W --> R
```
Unverified aliases are flagged for an admin to confirm.

## 3. Cycle count (Count mode)
```mermaid
flowchart TD
  A["Scan location"] --> B["Scan part"] --> C["Enter counted qty"]
  C --> D{"Differs from system qty?"}
  D -- no --> E["Record count, no change"]
  D -- yes --> F["Require note"] --> G["apply_movement type adjust for the difference"]
  E --> H["Next part"]
  G --> H
```

## 4. Part merge (SHOULD, later slice)
```mermaid
flowchart TD
  A["Admin selects duplicate and survivor"] --> B["Preview: aliases, stock, history affected"]
  B --> C["Confirm"] --> D["Repoint aliases, stock, movements, supplier_parts"]
  D --> E["Mark duplicate superseded_by survivor"] --> F["Write merge log"]
```
Alias conflicts (same normalized number and source on both parts) must be resolved before the merge proceeds.
