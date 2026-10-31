# Fixture: statement-grouped

Purpose: prove grouping, group scope, and pagination that crosses a group
boundary. This is the fixture that catches the most common engine bug:
losing the group context when a page ends.

## Must demonstrate

1. **Grouping** on `Transactions.Month` with the group declared in
   `groups` and referenced by both the group header and group footer.
2. **Group-scope aggregate** `MonthTotal` declared on the group and
   reset for each month; `GrandTotal` is report scope and accumulates.
3. **Page break inside a group.** With 60 detail rows and a 14 pt band,
   the document needs more than one page, and at least one break lands
   inside a month's rows.
4. **Repeated group header** after that break (`repeatHeader: true`), so
   the continuation page still says which month it belongs to.
5. **Push-down in the report header.** `cust-address` grows from 14 pt to
   several lines, and the `STATEMENT` title below it moves down instead of
   overlapping.
6. **Multi-page numbering** (`Page N of M`), which requires two passes.
7. **Keep-together** on the report footer, which must not be split even
   when it lands near the bottom of the last page.
8. Mixed-sign money formatting: charges positive, payments negative,
   two decimals, thousands grouping.

## Data

- `Customer`: one record with a long single-line address on purpose.
- `Transactions`: 60 records across three months (20 each). Dates ascend
  so sorting by `Date` keeps months contiguous.
- Parameters: `AccountNumber` (required), `PeriodLabel` (optional and
  deliberately omitted in `params.json` to prove optional handling).

## Known expected values

| Item | Expected |
|------|----------|
| Detail records | 60 |
| Groups | 3 |
| Page count | 2 or 3 (record the actual in the M3 golden) |
| Grand total | sum of all 60 amounts |
| Group subtotals | three values that sum to the grand total |
| Group header on a continuation page | present |

## Notes

- The page count is not asserted by hand in M0. It is recorded when the
  engine exists, and any later change to it is a reviewed golden change.
- `Month` is a string, not a date, on purpose: grouping is on the display
  key, so no locale-dependent date formatting can change group identity.
- This fixture is defined now but becomes an active gate in v0.2, when
  grouping ships.
