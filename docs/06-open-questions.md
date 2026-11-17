# Open questions

- [ ] Process requirements and flows are still under review (docs/01 and docs/03 are drafts). These have been reviewed and are good to move forward.
- [ ] Do any parts need serial or lot tracking? (Assumed no.) NO.
- [ ] Are there quantities in fractions (e.g. metres of trim) or only whole units? No fractions.
- [ ] Role needs in v1: scanners vs admins? (Starter policy lets any signed-in user edit catalog data.) Yes, lets have the ability to separate users and admins.
- [ ] Who may edit usernames? (Starter: users edit their own; admins via dashboard.) This is the correct understanding.
- [ ] Color codes are 3 characters and size codes 1 character. Assumed letters or digits, stored uppercase; confirm digits are wanted. (A single-character size allows at most 36 sizes.) Digits are not needed. Size code can be 1 to 3 alpha characters.
- [ ] Use the stricter suffix alphabet (also drop S, Z, B, 5, 2, 8) if labels are small or hand-read? For the part numbers use a stricter alphabet, but do NOT drop S, Z, B, 5, 2, 8.
- [ ] Priority of fitment features (REQ-050 to REQ-054): confirm SHOULD vs MUST. Currently this is SHOULD, but don't preclude the ability to implement this.
- [ ] Is there patchy Wi-Fi where scanning happens (offline queue priority)? It is possible, or where the user may want to build a list for label printing.
- [ ] Which barcode formats appear on existing parts (UPC/EAN, Code 128, QR, none)? We expect code 128, but we will test further if others appear.
- [ ] Label printer model and label sizes? The label printer is the Munbyn RW401AP, code 128 labels will be 3"x2" and location labels are either 3"x3" or 2"x1". 
- [ ] One warehouse or several? Depth of the location hierarchy? There is one warehouse per geographical location, currently there are 4 geographical locations.
- [ ] Source of existing part data (spreadsheet, ERP export)? How messy are duplicates? How will existing parts get silverton_skus assigned? Existing parts data are in spreadsheets. We can manually modify the spreadsheets into the proper import format. Upon the origination of a new part we expect the user to resolve any duplicate issues and have the aliases reflect anything required. To assign silverton_skus to existing parts - we plan to scan the factory part number and use this system to generate the new silverton_sku.
- [ ] Should Issue require a reason (repair, sale, damaged)? No, it will be assumed missing, wrong, or damaged.
- [ ] Who approves unverified aliases? Admins.
