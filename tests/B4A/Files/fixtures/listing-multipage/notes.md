# Fixture: listing-multipage

Purpose: prove pagination under volume, with repeated page headers and
two-pass page numbering. This is the fixture that fails first when
pagination is wrong.

## Must demonstrate

1. **Grid positioning.** `PageHeader` and `Detail` elements use `cell`
   coordinates on a 24-column grid (12 + 2 + 5 + 5 columns) instead of
   absolute `bounds`. The loader must resolve them to points against the
   content box.
2. **120 detail rows** across more than two pages at a 16 pt band.
3. **Repeated page header** on every page, including continuation pages.
4. **`Page N of M`** on every page, so the second pass must be exact.
5. **Report scope aggregate** `TotalAmount` and `RowCount` over the whole
   dataset, printed once at the end.
6. **Keep-together** on the report footer.
7. **Text growth inside a grid cell.** Several item descriptions exceed
   the 16 pt band height and must wrap without changing column widths.

## Data

- `Sales`: 120 records, generated deterministically (no randomness).
- Fields: `Region`, `Salesperson`, `Item`, `Quantity`, `Amount`.
- Parameters: `ReportTitle` (required); `PeriodStart` and `PeriodEnd`
  (optional, supplied as text).

## Known expected values

| Item | Expected |
|------|----------|
| Detail records | 120 |
| Detail band height | grows to fit the longest item within 255 pt |
| Page count | 3 (to be confirmed and frozen in the M3 golden) |
| `RowCount` | 120 |
| `TotalAmount` | sum of all 120 amounts |
| Page header on last page | present |

## Notes

- Grid columns are resolved as `contentWidth / 24`. The template does not
  assume square cells; `cellHeight` is set explicitly to 16.
- If `cell` positioning is later dropped from the schema, this fixture is
  the one that has to be rewritten, and that is an ADR-level change.
- The data is generated, so it is committed as JSON and treated as
  immutable. Regenerating it must produce byte-identical output.
