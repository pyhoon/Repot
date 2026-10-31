# B4XReport

A cross-platform reporting and document-generation engine for the B4X
ecosystem, written in B4X and licensed MIT.

B4XReport turns a portable report definition (`.b4xr`) plus data supplied
by the host application into paginated documents and structured exports.
The same template is intended to work from B4J desktop, B4J server, and
B4A, and to render to HTML for browsers.

> **Project status: M0 in progress.**
>
> This repository contains design documentation, the fixture set, and a
> B4J fixture checker. There is no engine yet. Every capability described
> here is planned and must not be read as implemented.

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

B4XReport is the engine those applications keep re-implementing: banded
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
   structures. XLSX and ODS produce real cells and values. CSV, XML, and
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

| Format | Intended use | Target release |
|--------|--------------|----------------|
| PDF | Fixed-layout, print-ready reports | 0.1 |
| HTML | Preview, web reports, printing | 0.1 |
| CSV | Flat tabular data | 0.1 |
| JSON | Data interchange and diagnostics | 0.1 |
| XML | Structured data interchange | 0.2 |
| DOCX | Editable word-processing documents | 1.0 |
| XLSX | Spreadsheets with real cells and values | 1.x |
| ODT | OpenDocument text | on request |
| ODS | OpenDocument spreadsheets | on request |

ODT and ODS are deliberately unscheduled. If demand appears, they are
implemented with the same office-document writer used for DOCX and XLSX.
No format is withheld from the MIT release.

## Target platforms

| Platform | Scope |
|----------|-------|
| B4J desktop | Generation, HTML preview, PDF/HTML/data output, printing where practical |
| B4J server | Headless generation to files or memory; no UI or JavaFX requirement |
| B4A | Template reuse and on-device output; native preview/print integration |
| Browser | Consumes generated HTML; optional lightweight viewer |
| B4i | Not targeted for 1.0. The architecture should not preclude it, but no claim is made. |

B4A delivery is scheduled after the B4J engine is stable, because
Android cannot use the same PDF backend. See
[docs/compatibility.md](docs/compatibility.md) and
[docs/decisions/0004-b4a-output-strategy.md](docs/decisions/0004-b4a-output-strategy.md).

## How it fits together

```text
  .b4xr template ──┐
                   ├─► template model ─► processing ─► layout ─► render document
  host data ───────┘        │                          │              │
  parameters ───────────────┘                          │              ├─► PDF
                                                       │              ├─► HTML
                                                       └─► data ──────├─► CSV / JSON / XML
                                                                      └─► DOCX / XLSX
```

Processing (binding, expressions, sorting, grouping, aggregates) is
shared. The visual pipeline then paginates and emits a render document;
exporters translate that render document into a format. Data exports use
the same processed data without pretending to paginate.

Details: [docs/architecture.md](docs/architecture.md).

## Quick start (API is not finalized)

The intended experience is two-phase: build a report once, then export it
to as many formats as needed without re-running layout.

```vb
Dim Report As B4XReport
Report.Initialize
Report.LoadTemplate(File.DirAssets, "Invoice.b4xr")
Report.SetDataSource("Items", InvoiceItems)      ' List of Maps or custom objects
Report.SetParameter("InvoiceNumber", "INV-1042")
Report.SetTimestamp(DateTime.Now)                ' explicit clock, no ambient time
Report.SetLocale("en-GB")                        ' explicit formatting culture

Wait For (Report.Build) Complete (Result As B4XReportResult)
If Result.Success Then
    Dim Pdf As B4XReportPdf
    Pdf.Initialize(Result)
    Wait For (Pdf.Export(File.DirApp, "invoice.pdf")) Complete (Ok As Boolean)
End If
```

Method and class names in this document are illustrative. Programmatic
report construction is equally supported; JSON-first must not mean
JSON-only. See [docs/api-design.md](docs/api-design.md).

## Repository layout

```text
B4XReport/
├── README.md
├── PLAN.md                      Engineering plan and milestone brief
├── CONTRIBUTING.md              Contribution terms, review and support policy
├── LICENSE                      MIT
├── docs/                        Design documentation
│   ├── decisions/               Architecture decision records
│   └── b4x-notes.md             Verified B4X API facts
├── source/
│   └── B4XReportTests/          Fixture checker (B4J console project)
├── demo/                        Minimal B4XPages demos for each platform
├── fixtures/                    Templates, data and notes; goldens from M3
└── tools/                       Developer scripts (fixture runner)
```

The fixture checker is the only working code today. It validates the
templates in `fixtures/` against the draft schema; it does not render
anything yet.

The engine ships as one `.b4xlib` containing all public modules, plus
optional jar dependencies where a format needs them. Exporters are
ordinary modules inside the library, not separate products. The real
optional boundary is the jar dependency, not the B4X module. See
[docs/decisions/0006-packaging.md](docs/decisions/0006-packaging.md).

## Documentation index

| Document | Contents |
|----------|----------|
| [PLAN.md](PLAN.md) | Scope, milestones, acceptance criteria, agent instructions |
| [docs/architecture.md](docs/architecture.md) | Layers, interfaces, units, determinism, error model |
| [docs/layout.md](docs/layout.md) | Band model, grid positioning, push-down, pagination |
| [docs/template-format.md](docs/template-format.md) | `.b4xr` schema draft |
| [docs/api-design.md](docs/api-design.md) | Public API shape and invariants |
| [docs/compatibility.md](docs/compatibility.md) | Platform matrix and fidelity tolerances |
| [docs/dependencies.md](docs/dependencies.md) | Dependency audit and licensing decisions |
| [docs/testing.md](docs/testing.md) | Fixtures, golden data, headless CI |
| [docs/b4x-notes.md](docs/b4x-notes.md) | Verified B4X API facts and gotchas |
| [docs/prior-art.md](docs/prior-art.md) | Existing B4X reporting tools and lessons |
| [docs/decisions/](docs/decisions/) | Recorded architecture decisions |

## What 1.0 means

Version 1.0 is a stable, versioned template format and a documented public
API, proven by:

- PDF output for multi-page, grouped reports with page numbering.
- HTML output from the same template.
- CSV, JSON, and XML data export from the same data preparation.
- DOCX output containing real paragraphs and tables, not images.
- A B4J desktop example, a B4J server example, and a B4A example that
  reuses the same template.
- Regression fixtures and documented fidelity tolerances.
- A dependency and license inventory.

## Non-goals

- Feature parity with Crystal Reports or JasperReports.
- A built-in database layer, query editor, or SQL execution from
  templates.
- A visual designer in 1.0. The designer is a separate application that
  consumes the public model and API.
- Identical pixel output across platforms and formats.
- Right-to-left text, complex script shaping, or text shaping ligatures in
  1.0.
- A support contract. The project is best-effort, MIT, and maintained by
  its author.

## License, support, and contributions

MIT. Everything in this repository. See [LICENSE](LICENSE).

There is no paid tier and no plan to close any source. Funding, if it
happens at all, will be in the form of sponsorship or paid integration
work under separate agreement, never by withholding capability. See
[docs/decisions/0001-open-source-model.md](docs/decisions/0001-open-source-model.md).

Support is best-effort through the issue tracker and the B4X forum.
There is no SLA. Contribution terms, review expectations, and the DCO
sign-off requirement are in [CONTRIBUTING.md](CONTRIBUTING.md).
