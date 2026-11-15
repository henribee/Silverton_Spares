# Open questions

- [ ] Process requirements and flows are still under review (docs/01 and docs/03 are drafts).
- [ ] Do any parts need serial or lot tracking? (Assumed no.)
- [ ] Are there quantities in fractions (e.g. metres of trim) or only whole units?
- [ ] Role needs in v1: scanners vs admins? (Starter policy lets any signed-in user edit catalog data.)
- [ ] Who may edit usernames? (Starter: users edit their own; admins via dashboard.)
- [ ] Color codes are 3 characters and size codes 1 character. Assumed letters or digits, stored uppercase; confirm digits are wanted. (A single-character size allows at most 36 sizes.)
- [ ] Use the stricter suffix alphabet (also drop S, Z, B, 5, 2, 8) if labels are small or hand-read?
- [ ] Priority of fitment features (REQ-050 to REQ-054): confirm SHOULD vs MUST.
- [ ] Is there patchy Wi-Fi where scanning happens (offline queue priority)?
- [ ] Which barcode formats appear on existing parts (UPC/EAN, Code 128, QR, none)?
- [ ] Label printer model and label sizes?
- [ ] One warehouse or several? Depth of the location hierarchy?
- [ ] Source of existing part data (spreadsheet, ERP export)? How messy are duplicates? How will existing parts get silverton_skus assigned?
- [ ] Should Issue require a reason (repair, sale, damaged)?
- [ ] Who approves unverified aliases?
