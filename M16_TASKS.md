# v1.7.0: Typed Spreadsheet Cells (M16)

**Current stage:** done. Scope: XLSX and ODS write real cell types
(numbers, booleans, dates) instead of string cells, with display formats
declared on dataset fields. No layout change, no new dependency, no schema
version bump. Decision record: [ADR 0011](docs/decisions/0011-spreadsheet-cell-types.md).

## Problem statement

Since v1.4 (XLSX) and v1.5 (ODS) every cell is a string. Excel and
LibreOffice therefore treat amounts as text: `SUM` returns 0, dates cannot
sort or filter as dates, and numbers are left-aligned. Prototype read-back
on this machine confirms it: `test-items.xlsx` and `test-items.ods` open in
Excel with `B2` as `String`, not `Double`. `docs/compatibility.md` records
this as a known limitation; `PLAN.md` section 15 lists "typed office cells"
as unscheduled.

## Verified before planning

Both package shapes were prototyped and opened through Excel COM; the
numbers below are from that run.

- XLSX numeric cell: `<c r="A2" s="1"><v>1234.5</v></c>` with
  `numFmtId="164" formatCode="#,##0.00"` reads back as `Double`,
  number format `#,##0.00`, text `1,234.50`.
- XLSX date cell: serial `46331` for 2026-11-05 (1899-12-30 epoch) with
  `yyyy-mm-dd` reads back as a date; a narrow column shows `########`, so
  column widths are part of the task.
- XLSX boolean: `t="b"` with `<v>1</v>` reads back as `Boolean`.
- ODS float/date/boolean with `office:value` / `office:date-value` /
  `office:boolean-value` read back as `Double`/`Boolean`, **but** with
  General format until an `office:automatic-styles` data style is attached
  by `table:style-name`. The cached `text:p` does not control Excel's
  display.
- Excel COM (`Excel.Application`, `DisplayAlerts=False`, read-only open) is
  available at `C:\Program Files\Microsoft Office\Root\Office16\EXCEL.EXE`
  and is the application-level gate for this milestone.

## Task 1: Schema - field display format
- [ ] `ReportFieldDef`: add `FormatMap As Map`, initialized empty.
- [ ] `ReportTemplateLoader`: accept `format` on a field (`CheckKeys`), parse
      with `ReportJsonUtil.MapAt`, same shape as style/element formats.
- [ ] `ReportJsonWriter`: emit `format` when non-empty, so save/reload stays
      canonical.
- [ ] `docs/template-format.md` section 4.4: document the optional field
      `format` and the default formats.
- [ ] Round-trip test still passes for `invoice-basic`, `listing-multipage`,
      `statement-grouped`.

## Task 2: Shared value/format helper
- [ ] New `source/ReportSpreadsheet.bas` (shared, pure B4X, no platform code):
      - `CellKind(Value, Field)` -> `number` / `boolean` / `date` / `text` / `empty`
        from the bound value (numeric ticks for date/datetime fields count as dates).
      - `ExcelSerial(Ticks)` and `OdfDateValue(Ticks)` from calendar
        components, timezone-free; parse the documented ISO forms for
        string-valued date fields and never read the ambient clock.
      - `ExcelFormatCode(FormatMap, DeclaredType)` -> `0`, `0.00`,
        `#,##0.00`, `"$"#,##0.00`, `yyyy-mm-dd`, ... ; quote literal
        prefix/suffix and double embedded quotes.
      - `OdfNumberStyle(Odf, FormatMap, Name)` and `OdfDateStyle(...)` ->
        the automatic-style fragments for content.xml.
      - `DisplayText(Value, FormatMap, DeclaredType)` for cached `text:p`
        and column-width measurement.
- [ ] Move the paginator's private `AddGrouping` into `ReportUnits` as a
      public helper (behaviour unchanged) so the spreadsheet display path
      and the layout use one implementation.
- [ ] Register the module in `source/B4J/Repot.b4j`, `source/B4A/Repot.b4a`,
      `tests/B4J/tests.b4j`, `tests/B4A/tests.b4a`.

## Task 3: XLSX writer
- [ ] Emit `xl/styles.xml`; add its content-type override and a workbook
      relationship (`rId2`). Include the two fills Excel expects
      (`none`, `gray125`), one font, one border, `cellStyleXfs` and
      `cellXfs`; custom `numFmt` ids start at 164.
- [ ] Emit typed cells: numeric `<v>`, `t="b"` for booleans, date serial
      with its `s` index, `t="inlineStr"` with `xml:space="preserve"` for
      text, `<c r=".."/>` for Null.
- [ ] Emit `<cols>` widths computed from the formatted text (clamp, e.g.
      8..60 characters) so dates and amounts are not `########`; place
      `<cols>` in schema order before `<sheetData>`.
- [ ] Keep the current canonical output deterministic: fixed part order,
      no timestamps, invariant number formatting.

## Task 4: ODS writer
- [ ] Emit `office:automatic-styles` in `content.xml` (after the root
      element, before `office:body`) with the number/date styles and
      `style:family="table-cell"` styles used by the cells (namespaces
      `style`, `number`).
- [ ] Emit typed cells: `office:value-type="float" office:value="..."`,
      `"boolean"` + `office:boolean-value`, `"date"` + `office:date-value`,
      `"string"` for text, bare `<table:table-cell/>` for Null; keep the
      cached `text:p` for consumers that read it.
- [ ] Emit per-column `table:style-name` with `style:column-width` so dates
      display instead of showing the serial number.
- [ ] Keep `mimetype` first and stored; the package shape must not regress
      (the v1.5 Excel repair-prompt fix).

## Task 5: Fixtures and tests
- [ ] Add `format` to the fields that need it in the office-facing fixtures
      (for example `invoice-basic.Items`: Quantity `0`, UnitPrice/Amount
      `#,##0.00` with grouping; keep the layout styles untouched).
- [ ] B4J `TestOfficeTypedCells` using a small in-code `.repot` definition
      with `Amount` (decimal + money format), `Due` (date), `Paid`
      (boolean), `Note` (string) and a Null row:
      - XLSX: styles part exists, `numFmt` code present, numeric `<v>`,
        `t="b"`, date serial equals the expected value, empty cell, column
        widths.
      - ODS: `office:value-type="float"` with `office:value`,
        `date-value` ISO, `boolean-value`, automatic style names referenced,
        column styles, `mimetype` still first and stored.
- [ ] B4J: invoice-basic export asserts `Quantity`, `UnitPrice`, `Amount`
      are numeric and carry the field format.
- [ ] B4A: export succeeds and files are non-empty; the structural typing
      is platform-neutral shared code, asserted once on B4J.
- [ ] No layout golden changes (field formats are exporter metadata).

## Task 6: Application-level verification
- [ ] New `tools/verify-office.ps1` (Windows + Excel; not part of CI):
      opens the exported XLSX and ODS read-only through
      `Excel.Application`, asserts cell value types, `NumberFormat` and
      `Text`, writes `=SUM(D2:D5)` into a spare cell, and fails unless the
      result is `2449.95`. Closes without saving and always quits Excel.
- [ ] Manual: open both files in Excel and confirm no repair prompt; open
      the ODS in LibreOffice when one is available (still Tier 2).

## Task 7: Docs, version, packaging
- [ ] `docs/compatibility.md`: remove "all cells are strings"; state the
      typed-cell behaviour, the date rules and the boolean display.
- [ ] `docs/testing.md`: Excel COM verification procedure and the new
      script; note LibreOffice remains unverified here.
- [ ] `CHANGELOG.md`: 1.7.0 Added/Fixed.
- [ ] `README.md`: output-format table and a short "What 1.7 delivered".
- [ ] `PLAN.md`: M16 row and drop typed cells from section 15.
- [ ] Version 1.7 in `ReportVersion.bas`, both `#LibraryVersion` headers,
      core manifest `Version=1.7`; repackage `dist/Repot.b4xlib` and
      install to `C:\B4X\Additional\B4X`.
- [ ] ADR 0011 status -> accepted.

## Files to create or change

| File | Change |
|------|--------|
| `source/ReportSpreadsheet.bas` | new shared cell-type/format helper |
| `source/ReportFieldDef.bas` | optional `FormatMap` |
| `source/ReportTemplateLoader.bas` | parse field `format` |
| `source/ReportJsonWriter.bas` | emit field `format` |
| `source/ReportUnits.bas` | public grouping helper (moved from paginator) |
| `source/ReportPaginator.bas` | call the shared grouping helper |
| `source/ReportXlsxExporter.bas` | styles part, typed cells, column widths |
| `source/ReportOdsExporter.bas` | automatic styles, typed cells, column widths |
| `source/B4J/Repot.b4j`, `source/B4A/Repot.b4a` | register module, version 1.7 |
| `tests/B4J/tests.b4j`, `tests/B4A/tests.b4a` | register module |
| `tests/B4J/ReportEngineTests.bas` | `TestOfficeTypedCells`, invoice assertions |
| `tests/B4A/ReportEngineTests.bas` | export smoke assertions |
| `tools/verify-office.ps1` | new Excel COM verifier |
| `tools/package-b4xlib.ps1` | manifest `Version=1.7` |
| `fixtures/invoice-basic/template.repot` (and other office fixtures as needed) | field `format` values |
| `docs/compatibility.md`, `docs/template-format.md`, `docs/testing.md`, `CHANGELOG.md`, `README.md`, `PLAN.md` | behaviour, formats, verification, release notes |
| `docs/decisions/0011-spreadsheet-cell-types.md` | status -> accepted |

## Acceptance

- [ ] `invoice-basic` XLSX/ODS open in Excel with **no repair prompt**;
      `Description` is text, `Quantity` a number, `UnitPrice`/`Amount`
      numbers displaying `1,200.00`, and `=SUM` of the amount column is
      `2449.95`.
- [ ] The typed test definition round-trips: date displays `yyyy-mm-dd`
      (no serial), boolean displays TRUE/FALSE, a Null cell is empty.
- [ ] Full gate green: `tools/run-fixtures.ps1` (B4J 510+ checks) and
      `tools/ci.ps1 -RunEmulator` (B4J + B4A), 0 errors, emulator-5554.
- [ ] Layout goldens unchanged.
- [ ] `tools/verify-office.ps1` exits 0 on the freshly exported files.
- [ ] `.b4xlib` repackaged as source-only with `Version=1.7`.

## Out of scope

- Formula cells and cached formula results.
- Cell styles beyond number formats (fills, borders, fonts) in office exports.
- DOCX/ODT typing: text documents have no cell type.
- Locale-specific currency or date formats beyond the declared pattern.
- LibreOffice verification (not installed on this machine).
