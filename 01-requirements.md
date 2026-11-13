# Requirements

Priority: **MUST** (v1), **SHOULD** (v1 if time), **LATER** (after v1).

## Catalog
- REQ-001 MUST: Each physical part has one canonical record with a unique local SKU. This SKU is referred to as silverton_sku and is generated with a combination of the part_code, color, assmbly_part, and a unique 4 character alphanumeric string, not including ambiguous letters and numbers.
- REQ-002 MUST: A part can have many aliases (manufacturer, supplier).
- REQ-003 MUST: An alias is unique per (normalized number, source). The same number from different sources may map to different parts.
- REQ-004 MUST: Matching ignores case, spaces, dashes, and punctuation (`AB-1234` = `ab 1234`).
- REQ-005 MUST: Aliases carry a `verified` flag; unverified matches are shown as such.
- REQ-006 MUST: Parts are never deleted; they are set to obsolete or superseded.
- REQ-007 SHOULD: A superseded part points to its replacement.
- REQ-008 SHOULD: Admin can merge two parts; aliases, stock, and history move to the survivor and the merge is logged.
- REQ-009 SHOULD: Parts can have photos.

## Locations
- REQ-010 MUST: Locations have a unique code and optional parent (warehouse > zone > shelf > bin).
- REQ-011 MUST: Each location has a scannable QR/barcode value.

## Stock and movements
- REQ-020 MUST: Every stock change is recorded as a movement; stock is never edited directly.
- REQ-021 MUST: Movement types: receive, move, issue, adjust.
- REQ-022 MUST: Stock at a location cannot go negative.
- REQ-023 MUST: Submitting the same idempotency key twice has no additional effect.
- REQ-024 MUST: Each movement records who, when, and an optional note.
- REQ-025 MUST: Show stock by part (with per-location breakdown) and by location.
- REQ-026 MUST: Show total on hand per part and flag parts at or below reorder point.
- REQ-027 MUST: Cycle count adjusts stock and requires a note.

## Scanning 
- REQ-030 MUST: PWA runs on iPhone and Android and scans using the camera.
- REQ-031 MUST: Mode selector: Receive, Move, Issue, Count.
- REQ-032 MUST: Scanning any known alias or SKU resolves to the canonical part.
- REQ-033 MUST: Unknown code prompts "Unkown Bar Code", "link to existing part" or "create new part" or cancel.
- REQ-034 MUST: Quantity defaults to 1 with a quick numeric entry.
- REQ-035 MUST: Clear success/error feedback after each scan; ready for the next.
- REQ-036 SHOULD: Offline queue with later sync (safe via REQ-023).
- REQ-037 MUST: Work with Bluetooth/USB keyboard-style scanners, and provide the option to use a phone-based scanner.

## Purchasing
- REQ-040 MUST: Supplier parts hold supplier part number, cost, lead time, MOQ, pack size, preferred flag.
- REQ-041 MUST: Creating a supplier part creates the matching alias automatically.
- REQ-042 LATER: Reorder suggestions from reorder point and lead time.

## Compatibility
- REQ-050 SHOULD: Record which products a part fits; search parts by product.

## Admin and reporting
- REQ-060 MUST: Admin screens for parts, aliases, locations, sources, suppliers.
- REQ-061 MUST: CSV import for parts, aliases, locations.
- REQ-062 MUST: Print location and part labels.
- REQ-063 MUST: Movement history per part and per location.

## Security and quality
- REQ-070 MUST: Users sign in; movements are attributed to a user.
- REQ-071 LATER: Roles (scanner vs admin).
- REQ-080 MUST: HTTPS everywhere (required for camera access).
- REQ-081 MUST: Row-level security on all tables.
- REQ-082 MUST: Schema changes only via migrations.
