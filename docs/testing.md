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
document, following [render-document.md](render-document.md):

```json
{
  "version": 1,
  "pages": [
    {
      "index": 1,
      "width": 595.2756,
      "height": 841.8898,
      "ops": [
        { "type": "text", "x": 360.00, "y": 12.00, "width": 78.42,
          "height": 21.60, "baseline": 17.20, "text": "INVOICE",
          "font": "DejaVu Sans", "size": 18.00, "bold": true,
          "italic": false, "underline": false, "colour": "#000000",
          "align": "left" },
        { "type": "image", "x": 0.00, "y": 0.00, "width": 130.00,
          "height": 48.00, "resource": "logo.png", "pixelWidth": 260,
          "pixelHeight": 96, "fit": "contain" },
        { "type": "rect", "x": 410.00, "y": 6.00, "width": 100.00,
          "height": 16.00, "fill": "#eeeeee" }
      ],
      "anchors": []
    }
  ]
}
```

Rules:

- Page dimensions use four decimal places; operation geometry uses two,
  rounded half-up.
- Ops in paint order; object keys in a fixed order, not map order.
- Empty optional strings and zero optional numbers are omitted.
- No timestamps, no absolute paths, no platform names, no image handles.
- Text is the resolved string, so a regression in binding or formatting
  shows up as a text diff.

Export goldens then check the parts geometry cannot: extracted PDF text,
actual page size in the file, HTML escaping, CSV line endings, JSON
types, and whether Word/LibreOffice can open the result.

## 3. Fixtures

```text
fixtures/
├── invoice-basic/
│   ├── template.repot
│   ├── data.json
│   ├── params.json
│   ├── logo.png
│   ├── notes.md                   what this fixture must prove
│   └── expected/                  goldens, generated in M3
├── listing-multipage/
├── multilang/                     Unicode scripts: Latin, Greek, Cyrillic,
│                                  Japanese, Chinese, Arabic, Hebrew, Korean
├── statement-grouped/
└── _fonts/                        added with the first PDF golden (M3)
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

### The headless harness (M0–M1)

`tests/B4J` is a B4J console project (originally `source/RepotTests`)
with two jobs:

1. **Fixture lint.** It validates every fixture against the draft schema.
2. **Engine unit tests.** It compiles the engine modules from
   `source/` through relative module references and runs the M1 and
   M2 tests: units, render-document construction/ordering/rounding,
   text measurement, loading, validation, canonical round-trip,
   expression reference scanning and dataset/parameter binding.

The fixture lint checks:

- required files, parseable JSON, `schemaVersion`;
- page size, orientation and margins;
- unique section and element IDs, allowed section and element types;
- exactly one of `bounds` or `cell` per element, four numeric bounds, grid
  columns not exceeded;
- every referenced font, style, dataset, group and aggregate exists;
- aggregate names are document-unique and aggregate fields exist;
- braced expressions resolve, with literal text outside braces ignored;
- image resources exist inside the fixture folder;
- every declared dataset is present in `data.json` with the declared
  fields and the right shape (array vs object);
- every required parameter is present in `params.json`.

It is a schema lint, not a renderer. It proves the fixtures and the schema
agree; it does not prove layout. Geometry goldens arrive in M3.

The engine tests use the same fixtures as real input. They load each
template, assert model values and diagnostics, save it to canonical JSON,
reload it, save again, and require the two saves to be identical. They
also check that two loads of the same file produce the same output. The
render-document tests check page indexing, operation order, defaults,
anchor storage, and half-up rounding to 0.01 pt. The measurement tests run
the B4J adapter with `java.awt.headless=true` and check font resolution,
fallback warnings, advance scaling, ascent/descent, line height, wrapping,
explicit breaks, over-wide words, trailing whitespace and empty blocks.

Run both with:

```powershell
.\tools\run-fixtures.ps1            # build + check + exit code
.\tools\run-fixtures.ps1 -NoBuild   # reuse the existing jar
```

To run from the B4J IDE, open `tests\B4J\tests.b4j` and
press F5. With no command-line arguments the harness probes
`..\..\fixtures`, `..\fixtures`, `fixtures`, then a deeper fallback, and
uses the first folder that exists. The PASS/FAIL lines appear in the IDE
Logs tab.

The wrapper treats a non-zero Java exit code as failure and removes the
previous result file before a run, so a stale `errors=0` cannot hide a
crash. It runs the harness with `-Djava.awt.headless=true`, so a
measurement path that needs a display fails the suite instead of passing
on a developer desktop.

The fixture checker was itself validated in M0 by injecting faults into a
copy of `invoice-basic` (bad style reference, unknown aggregate,
three-number bounds, missing image, renamed data field) and confirming it
reported all five. M1 adds negative tests for unknown styles, malformed
bounds, duplicate aggregates, unknown expression identifiers, missing
datasets, unknown section types, unbalanced expressions and unknown
parameters.

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

B4J ships a command-line builder. Verified on 2026-10-31 with B4J 10.7 and
Java 19:

```text
cd <project folder>
"C:\Program Files\B4X\B4J\B4JBuilder.exe" -Task=Build
```

- Exit code `0` on success, `1` on failure.
- Jar written to `Objects\<ProjectName>.jar`.
- Runs without the IDE and without a display.
- `-Task=BuildLibrary` is verified for the engine project: it needs
  `#LibraryName` in the project file and writes `Repot.jar` and
  `Repot.xml` to the B4J Additional folder (`%Additional%\B4J` on this
  machine), not to the project. Creating the `.b4xlib` is a packaging
  step, not a builder task.

`tools/run-fixtures.ps1` wraps the whole loop: build, run the checker with
the fixture path, read `Objects\fixture-check.txt`, and exit `0` only when
the summary line says `errors=0`. The wrapper exists because a B4J console
app cannot set a process exit code (see [b4x-notes.md](b4x-notes.md)).

CI shape:

```text
1. tools/run-fixtures.ps1                     # schema lint + engine tests, must exit 0
2. B4JBuilder -Task=Build on the engine project
3. B4JBuilder -Task=BuildLibrary on the engine project (packaging check)
4. java -jar <harness>.jar <fixtures> --golden  # from M3
5. compare layout JSON; fail on any diff
6. run verifier scripts for DOCX/XLSX when those exist
7. publish the diff as an artifact
```

The harness is a B4J console application; it does not need the IDE. Tests
are plain assertion subs and a small runner, so the project does not need
JUnit or any test framework.

`tools/ci.ps1` wraps the whole pipeline: B4J library build, fixture
suite, B4A library build, and (with `-RunEmulator`) the B4A suite on a
connected device. It exits 0 only when every enabled gate passes. Run
`tools/ci.ps1 -RunEmulator` for the full cross-platform gate.

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

## 7. Cross-platform (B4A) — verified M8

The same engine modules compile and run on B4A. The suite lives in
`tests/B4A` (previously `source/B4ATest`), with a per-platform test
module copy (`tests/B4A/ReportEngineTests.bas`, compiled with a
`B4A=true` header). Fixture assets are bundled under
`tests/B4A/Files/fixtures/` and copied to internal storage at runtime,
because asset folders cannot be listed or read directly.

Capability matrix (2026-11-02, B4ABuilder v14.20, emulator-5554,
API 36):

| Capability | B4J | B4A |
|------------|-----|-----|
| Loading, validation, parameters, binding | pass | pass |
| Layout + pagination (HTML/CSV/JSON/XML exports) | pass | pass |
| DOCX / XLSX export | pass | pass |
| PDF export, extracted text, goldens | pass | not applicable (`E-PDF-001` guard) |
| Layout goldens (AWT baselines) | pass | not applicable |
| Fixture-level validation | pass | not applicable |

This accounts for the check-count delta between platforms:
**B4J 407 checks, B4A 325 checks, 0 errors on both.** PDF remains
B4J-only for v1.x; on B4A the HTML print path is the documented
rendering route, and `ReportPdfExporter.Export` returns `False` with
diagnostic `E-PDF-001`.

Emulator workflow:

```text
build:   cd tests\B4A; "C:\Program Files\B4X\B4A\B4ABuilder.exe" -task=Build -obfuscate=False
install: C:\android\sdk\platform-tools\adb.exe install -r Objects\tests.apk
restart: adb shell am force-stop b4a.example; adb logcat -c
run:     adb shell am start -n b4a.example/.main
read:    adb logcat -d   →  PASS engine (325 checks), errors=0
```

The suite's pass/fail status is written to `fixture-check.txt` in
`File.DirInternal` and echoed to the log; the B4A test app also renders
the summary in a `TextView`. There is no skip helper: tests that cannot
apply to B4A log a skip line and return, which is why the check count
is lower while `errors=0`.

## 8. Export-specific checks

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

## 9. What is not tested automatically

- Print dialogs and printer drivers.
- WebView rendering on real Android devices.
- Appearance on every PDF reader.
- Performance on pathological inputs, beyond the documented limits.

These are recorded as manual checks in the release notes.

## 10. Acceptance rule

A milestone is complete when its fixtures pass, the build is green from
the command line, and the example in `demo/` runs. Not before.
