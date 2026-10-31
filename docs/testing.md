# Testing

Status: draft. This defines what "tested" means for this project, because
"it compiles in the IDE" is not a test.

## 1. Levels

| Level | What it checks | Speed |
|-------|----------------|-------|
| Unit | Parsing, validation, expressions, sorting, grouping, aggregates, formatting, unit conversion | fast |
| Layout golden | Page count and element geometry for each fixture | fast |
| Export golden | Format-specific invariants: PDF page count and text, HTML structure, CSV quoting, JSON round-trip, XML well-formedness, DOCX/XLSX openability | medium |
| Visual smoke | A small, pinned set of rendered pages checked as images | slow, optional |
| Cross-platform | Same fixture through B4J and B4A, semantics compared | manual gate |

## 2. Why geometry goldens, not pixel diffs

Pixel comparison of PDFs is brittle: font hinting, rasteriser version,
subpixel rounding, and anti-aliasing all change bytes without changing
the report. It produces false failures and trains maintainers to ignore
the suite.

Instead, layout writes a canonical JSON description of the render
document:

```json
{
  "fixture": "invoice-basic",
  "schemaVersion": "0.1",
  "pageCount": 1,
  "pages": [
    {
      "width": 595.28,
      "height": 841.89,
      "ops": [
        { "op": "text", "text": "INVOICE", "x": 360.0, "y": 12.0, "w": 78.42, "font": "DejaVu Sans", "size": 18, "bold": true },
        { "op": "image", "resource": "logo.png", "x": 0.0, "y": 0.0, "w": 130.0, "h": 48.0 },
        { "op": "rect", "x": 410.0, "y": 6.0, "w": 100.0, "h": 16.0, "fill": "#eeeeee" }
      ]
    }
  ]
}
```

Rules:

- Numbers rounded to 0.01 pt.
- Ops in paint order.
- No timestamps, no absolute paths, no platform names.
- Text is the resolved string, so a regression in binding or formatting
  shows up as a text diff.

Export goldens then check the parts geometry cannot: extracted PDF text,
actual page size in the file, HTML escaping, CSV line endings, JSON
types, and whether Word/LibreOffice can open the result.

## 3. Fixtures

```text
fixtures/
├── invoice-basic/
│   ├── template.b4xr
│   ├── data.json
│   ├── params.json
│   ├── expected/layout.json
│   ├── expected/document.txt      extracted PDF text
│   └── notes.md                   what this fixture must prove
├── listing-multipage/
├── statement-grouped/
└── _fonts/                        redistributable test fonts
```

Every fixture has a `notes.md` listing the behaviours it exists to
prove. A fixture without a stated purpose is deleted.

The first three fixtures are defined in M0, before the schema is frozen:

1. **invoice-basic** — logo, right-aligned money, auto-growing
   description, totals, one page.
2. **listing-multipage** — hundreds of rows, repeated page header, page
   number and page count, correct break point.
3. **statement-grouped** — group header, per-group subtotal, grand total,
   group header repeated after a page break. Defined in M0 as a design
   input; it becomes an active gate when grouping ships in v0.2.

## 4. Determinism harness

Every layout run in tests supplies:

- a fixed timestamp,
- a fixed locale (`en-GB` for most fixtures, one `de-DE` fixture for
  decimal comma),
- an explicit font set from `fixtures/_fonts`,
- a fixed data order.

Running the same fixture twice must produce byte-identical
`expected/layout.json`. That is a test, not an aspiration.

## 5. Headless build and CI

B4J ships a command-line builder:

```text
B4JBuilder.exe -Task=Build -BaseFolder <project> [-Project <file.b4j>] [-Configuration Default,b4j.example]
```

Behaviour to verify and record locally:

- exit code `0` on success, `1` on failure,
- output jar location under `Objects\`,
- whether `-NoClean` is needed for incremental builds,
- whether library builds use `-Task=BuildLibrary`.

CI shape:

```text
1. B4JBuilder -Task=Build   (test harness project)
2. java -jar Objects\B4XReportTests.jar --fixtures ..\fixtures --golden
3. compare golden JSON; fail on any diff
4. run verifier scripts for DOCX/XLSX when those exist
5. publish the diff as an artifact
```

The harness is a B4J console application; it does not need the IDE. Tests
are plain `Assert` subs and a small runner, so the project does not need
JUnit or any test framework.

Windows-only CI is acceptable and documented. B4A builds need the Android
SDK and a keystore, so they are a manual gate, not a CI job, initially.

## 6. Updating a golden

A golden change is a behaviour change and must be reviewed as such:

1. Run the harness with `--update`.
2. Inspect the diff. If element positions moved, explain why in the pull
   request and in the fixture's `notes.md`.
3. Never update goldens to make a failing build green without explaining
   the visual consequence.
4. A golden change that alters page count requires a screenshot or a
   rendered page in the pull request, even though the test itself is
   geometry-based.

## 7. Export-specific checks

- **PDF:** page count, page size, extracted text order, embedded font
  count, file opens in two independent readers. Optionally `qpdf
  --check`.
- **HTML:** parse as HTML, assert structure, assert no unescaped user
  text, assert page-break CSS present in layout mode.
- **CSV:** quoting of delimiter, quote, newline; CRLF vs LF option;
  UTF-8 BOM option; null representation.
- **JSON:** parse back and compare typed values, including nulls and
  decimals.
- **XML:** parse as well-formed, assert escaping and null representation.
- **DOCX:** open with an independent parser, assert paragraphs/tables
  exist as real structures, not images.
- **XLSX:** open with an independent parser, assert cell types, number
  formats, and sheet names.

## 8. What is not tested automatically

- Print dialogs and printer drivers.
- WebView rendering on real Android devices.
- Appearance on every PDF reader.
- Performance on pathological inputs, beyond the documented limits.

These are recorded as manual checks in the release notes.

## 9. Acceptance rule

A milestone is complete when its fixtures pass, the build is green from
the command line, and the example in `demo/` runs. Not before.
