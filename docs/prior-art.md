# Prior Art

Snapshot taken 2026-10-31 from public B4X forum threads. This is a
technical survey, not a review of anyone's work. Dates, reply counts, and
view counts are approximate and will drift; corrections are welcome.
Nothing here should be read as a criticism of the authors, several of whom
solved problems this project has not solved yet.

## 1. What exists

| Project | Author, date | What it is | What it does well | Where it stops |
|---------|--------------|------------|-------------------|----------------|
| jJasperReports | Juan Marrero, 2018–2024, ~111 replies | B4J wrapper for JasperReports | Battle-tested engine, free visual designer (Jaspersoft Studio), wide feature set | Heavy JVM dependencies; recurring "works in the IDE, fails in the deployed jar" class of problems; B4J only |
| jCrystalReports | Juan Marrero, 2018, ~95 replies | B4J wrapper for the Crystal Reports Java runtime | Familiar report paradigm for ex-VB developers | Requires a Business Objects/SAP install, 32-bit JRE, `CRConfig.xml` edits, and the runtime's iText 5.5 jars (AGPL); Windows-centric; B4J only |
| jNxtReportsB4J | Philip Chatzigeorgiadis, 2015, ~38 replies | Viewer for reports produced by Next-Reports | Shows an external-engine integration path | Requires the external tool; not a B4X reporting engine |
| xfood HTML Report Generator ("Tanuzzu Report") v2 | Xfood, 2026 | Browser-based visual designer producing `report.json`, consumed by B4X to emit HTML | Designer UX; no install; JSON output | HTML output only; no paginated layout engine, no grouping/totals pipeline |
| HTML template + JSON → PDF snippet | andrewmp, 2021 | Code snippet, not a library | Shows demand for template-driven PDF | No sections, bands, pagination, or aggregation; relies on a separate PDF step |
| "B4J Report writer steps" tutorial | PaulMeuris, 2024, 7 posts | Step-by-step build of a report-writer application | Complete workflow: DB browser → SQL editor → grid canvas → field codes → save/load → master/detail | Grid-only layout; SQL embedded in template tags; no pagination, grouping, typed data, or reusable API; series paused asking for direction |
| PD_PDFBox | behnam_tr, 2026 | PDFBox wrapper for B4J | Modern PDF primitives, maintained | Primitives only; caller does layout |
| openPDF wrapper | 2025 | OpenPDF wrapper for B4J | PDF primitives, permissive-ish licence | Primitives only |
| WebViewPdfExport | Segga, 2026 | Android HTML → PDF via WebView printing | Proves the Android print path works from B4X | Rendering only; no report model |
| XLUtils / jPOI 5 | Erel (official), 2021–2026 | Excel read/write for B4J | Official, free, capable | Spreadsheet access only, not reporting; also proves office-format wrappers are commodity |
| ABMaterial report export thread | 2018 | Discussion of exporting web-app reports | Demonstrates server-side export demand | No reusable engine |

## 2. Recurring failure modes

1. **Dependency and deployment friction.** Report engines that work in the
   IDE and fail as a standalone jar, or need an external runtime installed,
   lose their audience quickly.
2. **Primitives mistaken for a product.** A PDF library gives you text at
   coordinates. Callers then rebuild pagination badly, per application.
3. **The grid trap.** A fixed grid is easy to build and demo, but a
   non-square grid silently distorts geometry, and a grid alone has no
   answer for a row that grows or a page that ends mid-group.
4. **Data access inside the template.** SQL in the layout file makes
   templates unportable, unsafe to share, and impossible to unit-test.
5. **No reusable API.** Tutorial code is copied into applications, so it
   never improves, never versions, and never becomes cross-platform.
6. **Designer stalls.** The editor is the visible, satisfying part and the
   engine is the hard part; projects that start with the canvas run out of
   momentum before pagination exists.

## 3. What this project takes from the survey

| Lesson | Response | Record |
|--------|----------|--------|
| Syntax/build friction kills adoption | Pure B4X core, one `.b4xlib`, no install step | [ADR 0006](decisions/0006-packaging.md) |
| Grids help designers, hurt layout | Bands with optional grid-snapped children, normalised to points at load | [ADR 0002](decisions/0002-layout-model.md) |
| SQL in templates is a trap | Host-supplied datasets; engine cannot open a database | README, `PLAN.md` §6 |
| Pagination is the real gap | Layout and two-pass numbering specified before the schema | [layout.md](layout.md) |
| Free office wrappers already exist | No paid format tier; DOCX/XLSX are ordinary features | [ADR 0001](decisions/0001-open-source-model.md) |
| Designers ship before engines | Designer is explicitly out of scope until 1.0 | `PLAN.md` §7 |

## 4. Positioning

Not: "Crystal Reports for B4X". Almost nobody in this ecosystem has used
Crystal, and the ones who have associate it with desktop installs.

Instead: **the engine behind the report-writer application you keep
rebuilding** — bands, grouping, totals, pagination, one versioned
template, PDF and HTML and editable documents out, with data supplied by
your application instead of hidden in the layout.

Two claims must stay true for that positioning to survive:

1. Installation is a file copy, not a runtime install.
2. The same template really does render on B4J and B4A within the stated
   tolerances, or the documentation says exactly which parts do not.

## 5. Publishing without disparaging

When this project is announced, describe the gap, not other people's
work. Recommended framing:

> B4X has PDF primitives, wrappers around Java report engines, and several
> home-grown report writers. What is missing is a portable template format
> and a pagination engine that the same code can use on desktop, server,
> and Android. That is what this project is.

Do not compare feature counts with JasperReports or Crystal Reports in
marketing. Do not name iText as a "bad" dependency; simply state the
licence and let readers check. Credit prior work by name and link when
discussing why a template format was needed.
