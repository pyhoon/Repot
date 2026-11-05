# ADR 0011 - Spreadsheet cell types and field display formats

- Status: proposed
- Date: 2026-11-05

## Context

The office exporters write every cell as a string: XLSX uses `t="inlineStr"`,
ODS uses `office:value-type="string"`. Excel and LibreOffice therefore see
text, not data - amounts cannot be summed, dates cannot be sorted or filtered
as dates, and numbers are left-aligned. `docs/compatibility.md` records this
as a known limitation and `PLAN.md` section 15 lists it as unscheduled.

Typing the cells needs one decision beyond the encoding itself: where the
display format comes from. The dataset is a list of maps whose values the
binder has already normalized by declared type (string, integer, decimal,
boolean, date, datetime), but a field definition carries only a name and a
type. The layout has element and style formats, but:

- `docs/architecture.md` section 2 says an exporter must not reach into the
  template model to re-derive presentation;
- one field may appear in several bands with different formats, so "the
  layout format" is not always well defined;
- a dataset can be exported without being placed in any band at all.

## Decision

1. **Field-level format.** A dataset field definition may carry an optional
   `format` object, using the same shape as styles and elements: `type`
   (`number`, `date`, `text`, `boolean`) plus `decimals`, `grouping`,
   `prefix`, `suffix`, `pattern`, `trueText`, `falseText`. It is additive and
   backward compatible; templates without it keep working and load unchanged.

2. **Cell type follows the value, not only the declaration.** After binding:
   number -> numeric cell, boolean -> boolean cell, date/datetime with
   numeric B4X ticks -> date cell, string -> text cell, Null -> empty cell.
   A declared date/datetime field whose value is a string becomes a date
   cell only when it matches one of the documented ISO forms
   (`yyyy-MM-dd`, `yyyy-MM-dd HH:mm:ss`, `yyyy-MM-ddTHH:mm:ss`); any other
   string stays text.

3. **Format precedence.** The field's `format` when present; otherwise
   defaults by declared type: integer `0`, decimal `0.00`, date/datetime
   `yyyy-MM-dd` (datetime `yyyy-MM-dd HH:mm:ss`), boolean General.

4. **Dates are timezone-free.** Ticks are converted through calendar
   components (`DateTime.GetYear/Month/Day/...`) to an Excel serial
   (1899-12-30 epoch) and to an ODF `office:date-value` (ISO 8601), never
   through the ambient timezone. The 1900 leap-year bug only affects dates
   before 1900-03-01; it is documented, not emulated.

5. **Format encodings.** XLSX gains an `xl/styles.xml` part with custom
   `numFmt` entries (ids from 164), the two required fills, fonts, borders
   and `cellXfs`; column widths come from the formatted text. ODS gains
   `office:automatic-styles` number/date styles referenced by
   `table:style-name`, plus column styles. The ODS cached `text:p` alone is
   not enough: Excel's ODF importer displayed the serial number in the
   prototype until a data style was attached.

6. **Booleans display as TRUE/FALSE.** The report's `trueText`/`falseText`
   remain a layout feature; spreadsheets use the native boolean.

## Consequences

- Existing templates export typed values with default formats; authors who
  want 1,200.00 and a specific date pattern add `format` to the field.
- The template writer emits `format` so save/reload stays canonical.
- Layout is untouched: field formats are metadata for data exporters, so no
  page geometry or layout golden changes.
- Excel becomes the verification application for both formats on this
  machine (`tools/verify-office.ps1`); LibreOffice is still not installed,
  so ODS stays Tier 2 for LibreOffice specifically.
- Formula cells, cell styles beyond number formats, and DOCX/ODT typing stay
  out of scope; text documents have no cell type.

## Alternatives considered

- **Derive formats by scanning the layout for an element bound to the
  field.** Rejected: it violates the exporter/layout boundary, the
  first-match rule is ambiguous when a field appears in several bands, and a
  dataset that is exported but not laid out has no format at all.

- **Emit typed values with General formatting only.** Rejected: amounts lose
  grouping and decimals and dates display as serial numbers, which is worse
  for the reader than the current strings even though sums would work.

- **Keep everything as strings and let the user convert in Excel.** Rejected:
  that is the limitation this milestone removes; conversion is manual per
  export and breaks automation.

- **Bump the schema version.** Rejected: the property is optional and
  additive, and absent formats keep the previous behaviour; a version bump
  would imply migration work that does not exist.
