# Seed data

Known data goes here as CSV (UTF-8, header row). Describe known messiness below so tools do not guess.

| File | Columns |
|---|---|
| `categories.csv` | category_code (3 letters), name, notes |
| `colors.csv` | color_code (3 characters), name (3-character codes; a `NON` row already exists) |
| `sizes.csv` | size_code (1 character), name |
| `sources.csv` | name, kind (manufacturer/supplier/oem/internal/other), notes |
| `locations.csv` | code, name, parent_code, location_type, barcode_value |
| `products.csv` | code, name |
| `parts.csv` | import_key, category_code, color_code, size_code (optional), name, description, uom, reorder_point, reorder_qty, status, notes |
| `part_aliases.csv` | import_key, alias_number, alias_type, source_name, verified, notes |
| `part_fits_product.csv` | import_key, product_code, assembly_letter (optional), notes |

## How rows refer to each other
silverton_skus are generated when parts are inserted, so they cannot be in the input file. Give each part row a temporary `import_key` (any unique value, such as a spreadsheet row number). Alias and fitment rows reference parts by that `import_key`. The import step must write out a mapping file of `import_key` to generated `silverton_sku`, and keep it.

## Import order
categories, colors, sizes, sources, locations, products, parts, part_aliases, part_fits_product.

## Known data quality issues
- (list duplicates, inconsistent formats, unknown sources here)
