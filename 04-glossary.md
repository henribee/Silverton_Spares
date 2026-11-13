# Glossary

- **SKU**: Our local part number. Permanent identity of a physical part. Never reused.
- **Alias**: Any outside number that identifies a part (manufacturer, supplier, OEM, legacy, barcode).
- **Source**: Who issued an alias: a factory, supplier, OEM, or us.
- **Supplier part**: A buying relationship: part + supplier + their part number + terms.
- **Movement**: One immutable record of stock changing (receive, move, issue, adjust).
- **Stock**: Current quantity of a part at a location, derived from movements.
- **On hand**: Sum of stock for a part across all locations.
- **Idempotency key**: Client-generated unique value so a retried submit is not applied twice.
- **UoM**: Unit of measure (each, pair, set, bag of 10).
- **Cycle count**: Counting actual stock and adjusting the system to match.
- **Superseded**: A part replaced by a newer part; points to its replacement.
