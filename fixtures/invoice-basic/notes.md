# Fixture: invoice-basic

Purpose: prove the ordinary invoice path. This is the report every
commercial engine is judged on first.

## Must demonstrate

1. One page. Page size A4 portrait with millimetre margins converted to
   points at load.
2. Static labels, bound fields, an image resource, a horizontal rule, and
   a right-aligned currency column in one document.
3. **Auto-grow:** the third line item's description is deliberately long
   and must wrap, growing that detail band from its declared 16 pt without
   clipping.
4. **Report-scope aggregates:** `NetTotal` is the sum of `Amount` and
   `LineCount` is the number of detail records. Both are declared on the
   `Items` dataset and referenced bare.
5. **Keep-together:** the report footer must not be split; with this data
   it fits on the only page.
6. **Two-pass numbering:** `Page 1 of 1`, which requires knowing the page
   count before emitting.
7. Dataset access without a section dataset: `{Customer.Name}` resolves
   from a `single` dataset declared outside the detail band.

## Data

- `Customer`: one record (`Name`, `Address`).
- `Items`: four records. Row 3 has a deliberately long `Description`.
- Parameters: `InvoiceNumber` (required), `IssuedOn` (required, `datetime`).

Money values are round numbers so a human can verify the total by eye:
1200 + 350 + 800 + 99.95 = 2449.95.

## Known expected values

| Item | Expected |
|------|----------|
| Page count | 1 |
| Detail records | 4 |
| `NetTotal` | 2449.95 |
| `LineCount` | 4 |
| Long description lines | at least 3 at 9 pt in 240 pt |
| Report footer | on page 1, not split |

## Notes

- The template uses absolute `bounds` throughout. Grid positioning is
  covered by `listing-multipage`.
- `logo.png` is a placeholder. Resource resolution must stay inside this
  directory.
- Goldens are generated in M3; this file defines what they must show.

## Golden history

- 2026-11-05 (**v1.6**): regenerated. The font stack is
  `["DejaVu Sans", "Arial", "sans-serif"]`, so the intended resolution is
  DejaVu Sans; the M3 golden was produced on a machine without it and
  recorded `Arial` with smaller baselines. Regenerating on a machine with
  DejaVu Sans changes only `font`, `baseline`, and one wrap point: the
  long description now breaks after "licensed" instead of "hardware,".
  Box geometry (x/y/width/height) and the line count are unchanged, and
  the page still shows `Page 1 of 1`.
- Goldens therefore require **DejaVu Sans** to be installed. Without it
  the fallback is Arial and the layout golden will not match.
