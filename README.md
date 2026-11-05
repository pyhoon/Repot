<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/repot-logo-transparent.png">
    <img src="docs/assets/repot-logo-darkbg.png" alt="Repot logo" width="360">
  </picture>
</p>

<p align="center">
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-1.6.0-blue" alt="version 1.6.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/B4J-510%20checks%20%2F%200%20errors-success" alt="B4J 510 checks, 0 errors">
  <img src="https://img.shields.io/badge/B4A-353%20checks%20%2F%200%20errors-success" alt="B4A 353 checks, 0 errors">
</p>

# Repot

A cross-platform reporting and document-generation engine for the B4X
ecosystem, written in B4X and licensed MIT.

Repot turns a portable report definition (`.repot`) plus data supplied
by the host application into paginated documents and structured exports.
The same template works from B4J desktop, B4J server, and B4A, and
renders to HTML for browsers.

> **Project status: v1.6.0 (M15 complete).** The `Repot` facade
> (load → bind → build → export/print) is stable. v1.6.0 adds
> `Repot.GetHtml` (the exact HTML that `ExportHtml` writes), a viewport
> meta in the HTML output, and fixes B4A Save As, which could leave a
> 0-byte file. B4A produces vector PDF synchronously through the
> `Printing` library, verifies exported PDFs (`GetPdfPageCount` via
> `PdfRenderer`), prints through the system print dialog, and saves to a
> user-chosen location through the Storage Access Framework
> (`ReportSaveAs`). The B4J PDF embeds TrueType fonts, renders
> right-to-left text (bidi reordering + Arabic shaping), and accepts a
> set of embedded fonts for mixed-script documents. Office export covers
> DOCX, XLSX, ODT and ODS. Tagged `v1.6.0`.
>
> **Release scope:** v1.6.0 ships the core `Repot.b4xlib` only.
> `RepotViewer.b4xlib` and the `preview/` projects are test artifacts for
> the inline-preview work and are not released.
>
> The full engine suite runs on both platforms: **B4J 510 checks,
> B4A 353 checks, 0 errors on both** (emulator-5554, API 36).
> `tools/ci.ps1` is the B4J gate; add `-RunEmulator` (or run
> `tools/run-b4a-tests.ps1`) for the B4A suite, which fails when the
> summary line never appears. See [CHANGELOG.md](CHANGELOG.md).

## Why this exists

B4X developers who need real reports currently choose between three
unattractive options:

1. Wrap a Java reporting library such as Crystal Reports or JasperReports
   and absorb its dependency, licensing, and deployment problems.
2. Draw PDF primitives by hand for every report.
3. Build a report writer from scratch and maintain it forever.

Forum history shows all three happening repeatedly, and the from-scratch
attempts stall at roughly the same place: a grid canvas, a hand-rolled
template file, one hard-coded output format, and no pagination, grouping,
or data pipeline. The landscape is summarised in
[docs/prior-art.md](docs/prior-art.md).

Repot is the engine those applications keep re-implementing: banded
sections, grouping and totals, deterministic pagination, a versioned
template format, and as many output formats as a report can honestly
support.

## Design commitments

1. **MIT for everything.** Engine, exporters, adapters, documentation,
   fixtures, examples. No crippled edition, no license keys, no
   activator, no feature gating.
2. **Data belongs to the application.** The engine never opens a
   database and never executes SQL from a template. The host application
   supplies typed data through a provider interface.
3. **One template, several outputs, honest fidelity.** PDF is the
   fixed-layout target. DOCX and ODT produce editable document
   structures, XLSX and ODS produce real cells and values. CSV, XML, and
   JSON are data exports and do not pretend to be pages.
4. **The layout model is the product.** Text measurement, push-down,
   band overflow, and pagination are the hard parts. They are specified
   in [docs/layout.md](docs/layout.md) and exercised by fixtures before
   the template schema is frozen.
5. **Deterministic by default.** No ambient clock, locale, or filesystem
   access during rendering. Everything that varies is passed in
   explicitly, so identical input produces identical output.
6. **Platform independence.** No JavaFX, Android UI, browser DOM, or
   server request types in the core. Platform behaviour sits behind
   narrow adapters.

## Output formats

| Format | Intended use | Status |
|--------|--------------|--------|
| PDF | Fixed-layout, print-ready reports | shipped (B4J PDFBox with embedded fonts, RTL text and a mixed-script font set; B4A vector canvas); introspected via PDFBox / `PdfRenderer` |
| HTML | Preview, web reports, printing | shipped (fixed-layout: absolutely positioned pages with print CSS; responsive *flow* mode is not implemented) |
| CSV | Flat tabular data | shipped |
| JSON | Data interchange and diagnostics | shipped |
| XML | Structured data interchange | shipped |
| DOCX | Editable word-processing documents | shipped |
| XLSX | Spreadsheets with real cells and values | shipped |
| ODT | OpenDocument text | shipped (v1.5, dataset as a table; string cells) |
| ODS | OpenDocument spreadsheets | shipped (v1.5, dataset as a sheet; string cells) |

## Target platforms

| Platform | Scope |
|----------|-------|
| B4J desktop | Generation, HTML/PDF/data output, print (system viewer), PDF text extraction; inline preview only as a test artifact (`preview/`, not released) |
| B4J server | Headless generation to files; no UI or JavaFX requirement (`examples/server`); `ReportHtmlExporter.ToHtml` returns a document string |
| B4A | Same engine; on-device vector PDF export, PDF page-count verification, system print dialog, SAF "Save As" |
| Browser | Consumes generated HTML; optional lightweight viewer |
| B4i | Not targeted for 1.0. The architecture should not preclude it, but no claim is made. |

Android cannot use the same PDF backend, so B4A renders through its own
vector canvas (`Printing` library) and reads PDFs back through
`android.graphics.pdf.PdfRenderer`. See
[docs/compatibility.md](docs/compatibility.md),
[docs/decisions/0004-b4a-output-strategy.md](docs/decisions/0004-b4a-output-strategy.md)
and the M11 facts in [docs/b4x-notes.md](docs/b4x-notes.md).

## How it fits together

```text
  .repot template ──┐
                    ├─► template model ─► processing ─► layout ─► render document
   host data ───────┘        │                          │              │
   parameters ───────────────┘                          │              ├─► PDF
                                                        │              ├─► HTML
                                                        └─► data ──────┼─► CSV / JSON / XML
                                                                       └─► DOCX / XLSX / ODT / ODS
```

Processing (binding, expressions, sorting, grouping, aggregates) is
shared. The visual pipeline then paginates and emits a render document;
exporters translate that render document into a format. Data exports use
the same processed data without pretending to paginate.

Details: [docs/architecture.md](docs/architecture.md).

## Quick start

Install `dist/Repot.b4xlib` into your additional libraries folder. The
shared folder `C:\B4X\Additional\B4X` is read by both B4J and B4A, so one
copy there serves both IDEs; per-IDE folders work too. On
B4J, PDF export and introspection also need Apache PDFBox: place
`pdfbox-app-3.0.8.jar` in the additional libraries folder (the b4xlib
manifest declares it under `B4J.DependsOn`, so the compiler resolves
it from there; the jar itself is not bundled — download from Maven
Central). B4A needs nothing extra. See
[docs/dependencies.md](docs/dependencies.md).

Inline preview is **not part of the shipped library**. `RepotViewer.b4xlib`
and the `preview/` projects are test artifacts for the inline-preview work:
they build, and the B4A branch is verified on an emulator, but v1.6.0
releases only the core `Repot.b4xlib`. If you build the viewer yourself
(`tools/package-viewer-b4xlib.ps1`), install it the same way — one copy in
`Additional\B4X` covers both IDEs. It contains `ReportHtmlViewer`, a B4X
custom view for the Layout Designer's Custom Views list; B4J needs
`jfx` + `jxui`, B4A needs `xui`. The core engine library stays headless.

Build a report once, then export it to as many formats as needed without
re-running layout. The facade is synchronous: `Build` and the exporters
return immediately.

```vb
Dim Report As Repot
Report.Initialize
Report.LoadTemplate(File.DirAssets, "invoice.repot")
Report.SetDataSource("Items", InvoiceItems)      ' List of Maps
Report.SetDataSourceSingle("Customer", Customer) ' Map for single-record datasets
Report.SetParameter("InvoiceNumber", "INV-1042")

Dim Result As ReportResult = Report.Build
If Result.Success = False Then
    For Each D As ReportDiagnostic In Result.Errors
        Log(D.Code & ": " & D.Message)
    Next
    Return
End If

Report.ExportPdf(File.Combine(DirApp, "invoice.pdf"))
Report.ExportHtml(File.Combine(DirApp, "invoice.html"))
Report.ExportCsv(File.Combine(DirApp, "items.csv")) ' DefaultDataSet; ExportCsvOf for another dataset

' Verify the PDF (B4J PDFBox, B4A PdfRenderer; 0 when unreadable)
Log(Report.GetPdfPageCount(File.Combine(DirApp, "invoice.pdf")))
```

On B4A, printing and saving to a user-chosen location need a little host
wiring (no permissions, no manifest entry):

```vb
Report.PrintPdf(DirApp, "invoice.pdf", "Invoice")          ' system print dialog

' Save As: launch the SAF picker and wait for its IOnActivityResult event.
' B4A does NOT deliver SAF results to Activity_Result.
Dim i As Intent = Report.SaveAsPdfIntent("application/pdf", "invoice.pdf")
Dim ba As JavaObject = GetBA
ion = ba.CreateEvent("anywheresoftware.b4a.IOnActivityResult", "ion", Null)
ReportSaveAs.StartForResult(ba, ion, i)
Wait For ion_Event (MethodName As String, Args() As Object)
If Args(0) = -1 Then    ' RESULT_OK
    Dim result As Intent = Args(1)
    ReportSaveAs.CopyFileToUri(DirApp, "invoice.pdf", result.GetData)
End If

Private Sub GetBA As JavaObject
    Dim jo As JavaObject
    Dim cls As String = Me
    cls = cls.SubString("class ".Length)
    jo.InitializeStatic(cls)
    Return jo.GetField("processBA")
End Sub
```

`ReportSaveAs.SaveToDownloads(Dir, Name, Mime)` is an alternative that
writes straight to the public Downloads collection (MediaStore, API 29+)
and returns the URI — no picker and no `Wait For`.

Examples using the same invoice template on all three platforms live in
`examples/B4J`, `examples/B4A`, and `examples/server` (an HTTP server
that renders `/report/pdf`). See [docs/api-design.md](docs/api-design.md)
for the full facade and [docs/decisions/0006-packaging.md](docs/decisions/0006-packaging.md)
for distribution as a `.b4xlib`.

## Repository layout

```text
Repot/
├── README.md
├── PLAN.md                      Development plan and coding-agent brief
├── CHANGELOG.md                 Release notes per version
├── CONTRIBUTING.md              Contribution terms, review and support policy
├── LICENSE                      MIT
├── docs/                        Design documentation (see index below)
│   └── decisions/               Architecture decision records
├── source/                      Engine modules (one .bas per class/module)
│   ├── B4J/                     B4J library project
│   └── B4A/                     B4A library project (same modules, |relative| refs)
├── tests/                       Fixture checker and engine unit tests
│   ├── B4J/                     Console test project (also used by headless CI)
│   └── B4A/                     Same suite on device/emulator
├── examples/
│   ├── B4J/                     Desktop example
│   ├── B4A/                     Android example (export, print, SaveAs)
│   └── server/                  B4J HTTP server serving rendered reports
├── preview/                     Test artifact: viewer module + designer apps
│   ├── ReportHtmlViewer.bas     Designer-addable custom view (B4J + B4A)
│   ├── B4J/                     B4J preview app (designer-added view)
│   └── B4A/                     B4A preview app (designer-added view)
├── fixtures/                    Templates, data and notes; layout/export goldens
├── dist/                        Repot.b4xlib (released) + RepotViewer.b4xlib (test artifact)
└── tools/                       Developer scripts (ci.ps1, run-fixtures.ps1, run-b4a-tests.ps1, packaging)
```

The engine ships as one `.b4xlib` containing all public modules. The
viewer module lives in `preview/` and is packaged separately
(`RepotViewer.b4xlib`) so the core library never pulls in a UI stack; it
is a test artifact, not a released package. The B4J
and B4A library projects both reference the shared modules in `source/`
through relative module references, so one source base serves both
targets. Exporters are ordinary modules inside the library, not separate
products; the real optional boundary is the jar dependency, not the B4X
module.

## Documentation index

| Document | Contents |
|----------|----------|
| [CHANGELOG.md](CHANGELOG.md) | What changed in each release |
| [PLAN.md](PLAN.md) | Scope, milestones, acceptance criteria, agent instructions |
| [docs/architecture.md](docs/architecture.md) | Layers, interfaces, units, determinism, error model |
| [docs/layout.md](docs/layout.md) | Band model, grid positioning, push-down, pagination |
| [docs/template-format.md](docs/template-format.md) | `.repot` schema reference |
| [docs/schema-review.md](docs/schema-review.md) | Fixture-driven review that closed M0 |
| [docs/render-document.md](docs/render-document.md) | Versioned display list consumed by exporters |
| [docs/api-design.md](docs/api-design.md) | Public API shape and invariants |
| [docs/compatibility.md](docs/compatibility.md) | Platform matrix and fidelity tolerances |
| [docs/dependencies.md](docs/dependencies.md) | Dependency audit and licensing decisions |
| [docs/errors.md](docs/errors.md) | Stable diagnostic codes |
| [docs/testing.md](docs/testing.md) | Fixtures, golden data, headless CI |
| [docs/b4x-notes.md](docs/b4x-notes.md) | Verified B4X API facts and gotchas |
| [docs/prior-art.md](docs/prior-art.md) | Existing B4X reporting tools and lessons |
| [docs/decisions/](docs/decisions/) | Recorded architecture decisions |
| [M10_TASKS.md](M10_TASKS.md)–[M15_TASKS.md](M15_TASKS.md) | Milestone plans and completion state |

## What 1.0 delivered

Version 1.0 was the stable, versioned template format and a documented
public API, proven by:

- PDF output for multi-page, grouped reports with page numbering.
- HTML output from the same template.
- CSV, JSON, and XML data export from the same data preparation.
- DOCX and XLSX output containing real paragraphs, tables, and cells,
  not images.
- A B4J desktop example, a B4J server example, and a B4A example that
  reuse the same template.
- Regression fixtures and documented fidelity tolerances.
- A dependency and license inventory.

## Non-goals

- Feature parity with Crystal Reports or JasperReports.
- A built-in database layer, query editor, or SQL execution from
  templates.
- A visual designer. The designer is a separate application that
  consumes the public model and API.
- Identical pixel output across platforms and formats.
- A support contract. The project is best-effort, MIT, and maintained by
  its author.

## What 1.3 delivered

Right-to-left text in the B4J PDF, the one capability explicitly
deferred from v1.2.0:

- Bidi run reordering (`java.text.Bidi`) so logical-order Arabic and
  Hebrew strings draw in correct visual order; digits inside an RTL
  span stay left-to-right.
- Arabic contextual shaping through the Unicode presentation forms
  (U+FE70–FEFF) including the mandatory lam-alef ligatures, flowing
  through the existing PDFBox embed/subset path so extracted text stays
  readable and searchable.
- Embeddable Noto Sans Arabic and Noto Sans Hebrew fonts (SIL OFL 1.1)
  verified against the pipeline, plus `rtl-arabic` and `rtl-hebrew`
  fixtures. B4A needed no changes: the system text stack shapes at
  draw time.

## What 1.4 delivered

Mixed-script documents and paragraph direction, closing v1.3's own
known limitations:

- `ReportPdfExporter.AddEmbeddedFont`: additional embedded font pairs
  beyond the primary `FontFile`/`FontFileBold`. Text is split into
  maximal per-font runs, so one export can mix Latin, Arabic and
  Hebrew — including digits inside Hebrew text, which no single Noto
  font covers.
- `BaseDirection` ("ltr"/"rtl"): bidi paragraph base direction for the
  PDF pass; pure-RTL lines keep trailing punctuation on the left edge.
- A shaping fix found during verification: Arabic letters joined from
  the right no longer take the medial form when the next character is
  not a joiner.
- The `mixed-scripts` fixture exercises all of it on both platforms.

## What 1.5 delivered

The office-formats family is complete:

- `ReportOdtExporter` and `ReportOdsExporter`: OpenDocument text and
  spreadsheet output from the same dataset preparation as DOCX/XLSX,
  using the same own-minimal-writer approach (zip + XML, no new
  dependencies). The ODF package rules are honoured — `mimetype` is the
  first zip entry and uncompressed — and the suite asserts the package
  structure and content XML directly.
- `Repot.ExportOdt` / `Repot.ExportOds` on the facade.
- Known limitation, documented: cells are written as strings, matching
  the XLSX writer's behaviour; typed numeric/date cells remain future
  work for both office spreadsheet writers.
- CJK verification: the `multilang` fixture now embeds Noto Sans SC/KR
  subsets plus the Arabic/Hebrew pairs, and the suite asserts every
  script extracts from the PDF with zero `?` substitutions — Japanese,
  Chinese and Korean render in the B4J PDF whenever a covering font is
  registered (`AddEmbeddedFont`).

## What 1.6 delivered

The accessor that makes a preview trustworthy, plus the fixes the preview
work exposed. **The viewer itself is a test artifact, not a release.**

- `Repot.GetHtml` returns the same HTML document `ExportHtml` writes.
  One render document, one exporter pass — a preview cannot differ from
  the exported file.
- HTML output carries `<meta name="viewport" content="width=device-width,
  initial-scale=1">`, so the fixed-width page is no longer laid out at
  desktop width on a phone.
- B4A Save As no longer writes 0-byte files. B4A does not deliver SAF
  results to `Activity_Result`, so `ReportSaveAs.StartForResult` now takes
  the host's BA and `IOnActivityResult` event and the host uses
  `Wait For`; `CopyFileToUri` opens the stream with `"wt"`. Verified on an
  emulator: a 21 KB PDF at the chosen location.
  `ReportSaveAs.SaveToDownloads` is the no-picker alternative.
- `ReportB4APrint.PrintVectorPdf` fails when the written PDF is 0 bytes;
  existence alone is no longer treated as success.
- Layout goldens were regenerated against the fixtures' preferred font
  (DejaVu Sans). Only `font`/`baseline` changed, plus one wrap point.
- B4A coverage for the Save As path (`TestSaveAs`) and
  `tools/run-b4a-tests.ps1`, which fails when the summary line is missing.

**Test artifacts (not shipped):** `ReportHtmlViewer` in `RepotViewer.b4xlib`
(a B4X custom view: `DesignerCreateView` + `PageFinished`, B4J
`fx.WebView` / B4A core `WebView`, scales the page to the view width) and
the `preview/B4J` + `preview/B4A` apps. The B4A preview was run on an
emulator (renders inline, fits width, Save As 21 KB). The B4J preview is
compile-verified only — this machine's JDK has no JavaFX runtime, so the
window cannot start.

## License, support, and contributions

MIT. Everything in this repository. See [LICENSE](LICENSE).

*Note on Dependencies: This library dynamically links to Apache PDFBox at runtime. Apache PDFBox is governed by the Apache License 2.0.*

There is no paid tier and no plan to close any source. Funding, if it
happens at all, will be in the form of sponsorship or paid integration
work under separate agreement, never by withholding capability. See
[docs/decisions/0001-open-source-model.md](docs/decisions/0001-open-source-model.md).

Support is best-effort through the issue tracker and the B4X forum.
There is no SLA. Contribution terms, review expectations, and the DCO
sign-off requirement are in [CONTRIBUTING.md](CONTRIBUTING.md).
