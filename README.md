# B4XReport

A cross-platform reporting and document-generation framework for the B4X
ecosystem.

B4XReport is intended to let developers define a report once and use
that definition from B4J desktop applications, B4J server applications,
and B4A Android applications. The same report definition should also be
usable by the HTML/browser output pipeline.

The project aims to provide the reusable reporting foundation that B4X
applications currently have to assemble from separate libraries and
custom code.

> **Project status:** Planning / initial implementation.
>
> This README describes the intended product. It is not a claim that
> every listed feature is already implemented.

## Goals

1.  Define reports in a portable, versioned JSON-based template format
    (`.b4xr`).
2.  Keep report processing independent of B4J, B4A, JavaFX, Android UI
    classes, and browser APIs.
3.  Reuse the same data binding, expressions, grouping, aggregation, and
    layout rules across supported platforms.
4.  Support both visual document generation and structured data export.
5.  Provide a programmatic API as well as a future visual report
    designer.
6.  Make exporters optional so applications only include the formats
    they need.
7.  Keep templates portable, inspectable, version-controllable, and
    independent of any one application.

## Target platforms

### Initial targets

-   **B4J desktop:** report generation, preview, PDF/HTML output, and
    desktop integration.
-   **B4J server:** server-side generation of PDF, HTML, and supported
    document/data formats; suitable for REST endpoints, downloads,
    scheduled reports, and email attachments.
-   **B4A:** Android report generation and native preview/printing
    integration where supported.
-   **Web/browser:** HTML output and a lightweight browser viewer.
    Browser rendering is an output target; it must not become a
    dependency of the shared core.

### Future consideration

-   **B4i:** Keep the architecture portable enough to allow a future
    adapter, but do not make B4i support a blocker for the first
    release.

## Output formats

The architecture must accommodate these formats:

  -----------------------------------------------------------------------
  Format                  Intended use            Pipeline
  ----------------------- ----------------------- -----------------------
  PDF                     Fixed-layout documents  Visual
                          and print-ready reports 

  HTML                    Browser preview, web    Visual
                          reports, printing       

  DOCX                    Editable                Document
                          word-processing         
                          documents               

  ODT                     OpenDocument text       Document
                          documents               

  XLSX                    Editable spreadsheets,  Spreadsheet/data
                          formulas, worksheets    

  ODS                     OpenDocument            Spreadsheet/data
                          spreadsheets            

  CSV                     Flat tabular data       Data

  XML                     Structured data         Data
                          interchange             

  JSON                    Structured data         Data
                          interchange and         
                          diagnostics             
  -----------------------------------------------------------------------

The implementation should not assume that every output format can
reproduce identical visual layout. PDF is the primary fixed-layout
target. DOCX and ODT should create editable document structures. XLSX
and ODS should create real cells, values, formulas where appropriate,
worksheets, and spreadsheet formatting. CSV, XML, and JSON are data
exports and do not need to preserve page layout, logos, or page numbers.

## Architectural principles

### 1. One template, multiple renderers/exporters

A `.b4xr` template describes report content, data bindings, layout,
sections, groups, parameters, and formatting. Platform-specific adapters
and format exporters consume the shared report model.

### 2. Separate processing from rendering

The shared processing pipeline should handle:

-   Template parsing and validation
-   Parameters and data binding
-   Sorting and grouping
-   Expressions and calculated values
-   Aggregations and running totals
-   Layout measurement and pagination where applicable
-   A normalized intermediate report model

Renderers/exporters should convert that model into their respective
output formats.

### 3. Separate visual output from data export

Maintain two related pipelines:

-   **Visual/document pipeline:** layout, text measurement, sections,
    pagination, drawing, and document generation.
-   **Data pipeline:** rows, columns, typed values, group results, and
    serialization.

They may share data preparation and expression evaluation, but they must
not force CSV or XML to behave like paginated documents.

### 4. Platform-independent core

The core must not directly depend on:

-   JavaFX classes
-   Android View or Canvas classes
-   Browser DOM APIs
-   B4J server request/response objects
-   A specific database engine

Use narrow interfaces/adapters for platform-specific drawing, text
measurement, file access, fonts, printing, and server integration.

### 5. Optional exporters

A developer should be able to include only the required exporter
modules. Do not make a PDF-only application depend on spreadsheet or
word-processing libraries.

### 6. Portable templates

Templates should be JSON-based, UTF-8, versioned, and deterministic. Use
stable identifiers for report elements. Keep localized text, themes, and
runtime data separate from structural identity where practical.

## Conceptual module layout

The final repository layout may be adjusted after dependency validation,
but preserve these responsibilities:

``` text
B4XReport/
├── README.md
├── PLAN.md
├── LICENSE
├── docs/
│   ├── architecture.md
│   ├── template-format.md
│   ├── api-design.md
│   └── compatibility.md
├── src/
│   ├── B4XReportCore/
│   ├── B4XReportLayout/
│   ├── B4XReportPDF/
│   ├── B4XReportHTML/
│   ├── B4XReportCSV/
│   ├── B4XReportXML/
│   ├── B4XReportJSON/
│   ├── B4XReportB4J/
│   └── B4XReportB4A/
├── commercial/
│   ├── B4XReportDOCX/
│   ├── B4XReportXLSX/
│   ├── B4XReportODF/
│   └── B4XReportDesigner/
├── examples/
│   ├── B4J/
│   ├── B4A/
│   ├── Server/
│   └── Templates/
└── tests/
    ├── Core/
    ├── Layout/
    ├── Exporters/
    └── Fixtures/
```

This is a conceptual structure, not a requirement to create empty
modules immediately. Keep proprietary components out of the public
source repository if they are not intended to be distributed under the
public license.

## Proposed public/commercial boundary

The current proposal is:

### Public, MIT-licensed

-   B4XReportCore
-   B4XReportLayout
-   PDF exporter
-   HTML exporter
-   CSV exporter
-   XML exporter
-   JSON exporter
-   B4J and B4A integration adapters, subject to dependency review
-   Basic examples and documentation

### Commercial, separately distributed

-   DOCX exporter
-   XLSX exporter
-   ODT/ODS exporter
-   Visual report designer
-   Premium support and custom integrations

This boundary is a product proposal, not a substitute for legal review.
Verify the license and redistribution terms of every third-party
dependency. Do not copy or bundle code/assets whose license is
incompatible with the intended distribution. Keep the public core
genuinely useful; do not deliberately cripple basic reporting features
to force an upgrade.

The project should not depend on community contributions to meet its
roadmap. Contributions may be accepted later under a clearly documented
process, but the maintainer remains responsible for planning,
implementation, releases, and support.

## Quick-start direction (API is not finalized)

The intended developer experience should be concise and asynchronous
where generation can take significant time. The following is
illustrative pseudocode only; do not treat method names or signatures as
finalized:

``` vb
Dim Report As B4XReport
Report.Initialize
Report.LoadTemplate(File.DirAssets, "Invoice.b4xr")
Report.SetDataSource("Items", InvoiceItems)
Report.SetParameter("InvoiceNumber", InvoiceNumber)

Wait For (Report.Generate) Complete (Result As B4XReportResult)

If Result.Success Then
    ' Export using the required exporter.
End If
```

Also support programmatic report construction. JSON-first must not mean
JSON-only.

## Template design requirements

The template specification must define, at minimum:

-   Schema version and report metadata
-   Page size, orientation, units, and margins
-   Report sections (report header/footer, page header/footer, group
    header/footer, detail)
-   Stable IDs for sections and report elements
-   Text, field, image, line, rectangle, and other basic elements
-   Data sources, fields, and parameters
-   Sorting and grouping
-   Expressions and aggregate definitions
-   Formatting, alignment, borders, visibility, and conditional
    formatting
-   Page-break and pagination behavior
-   Resource references (images and fonts)
-   Export-specific hints without making the base template format
    exporter-dependent

Unknown optional properties should be handled safely. Breaking schema
changes require a version increment and migration/compatibility policy.

## Non-goals for the first release

-   Full feature parity with SAP Crystal Reports
-   A complete visual designer before the engine is stable
-   Arbitrary user-supplied executable code inside templates
-   A universal database ORM
-   Identical layout fidelity across PDF, DOCX, ODT, HTML, and
    spreadsheets
-   Mandatory B4i support in the first release
-   Mandatory dependence on a specific web framework or B4J server
    framework

## Development approach

Build and validate the engine in B4J first, because desktop debugging
and visual inspection are practical there. Keep the core portable from
the beginning, then implement B4A integration and test the same
templates on Android.

The first useful release should prioritize a reliable invoice and
multi-page tabular report workflow over advanced features.

See [PLAN.md](PLAN.md) for milestones, acceptance criteria, risks, and
coding-agent instructions.
