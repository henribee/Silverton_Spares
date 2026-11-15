# Overview

## Purpose
Track furniture spare parts across storage locations, using a phone to scan stock in, out, and between locations, with accurate levels per part and per location.

## Users
- **Warehouse staff**: scan receive / move / issue on a phone.
- **Admin / purchasing**: manage parts, aliases, locations, suppliers; review stock and low-stock reports.

## Core problem
The factory puts different part numbers on identical parts. The system keeps **one canonical record per physical part** (local SKU) and maps every outside number (manufacturer, supplier, OEM, legacy, barcode) to it.

## Scope (v1)
- Part catalog with SKU + alias cross-reference
- Locations with scannable labels
- Movement ledger and current stock
- Phone scanning (PWA) with Receive / Move / Issue / Count modes
- Supplier part numbers and basic terms
- Low-stock view, movement history, CSV import, label printing

## Non-goals (v1)
- Serial or lot tracking
- Order management, invoicing, or sales
- Multi-company tenancy
- Native iOS/Android apps

## Success looks like
A person can scan a location, scan any known number on a part, confirm a quantity, and see correct stock immediately, with no duplicate parts created.
