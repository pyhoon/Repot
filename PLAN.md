# B4XReport --- Development Plan and Coding-Agent Brief

**Document status:** Initial project specification\
**Project:** B4XReport\
**Primary language/ecosystem:** B4X (B4J and B4A first)\
**Template format:** Versioned JSON, using the `.b4xr` extension\
**Initial implementation strategy:** B4J-first development with a
platform-independent core

------------------------------------------------------------------------

## 1. Mission

Build a cross-platform reporting and document-generation framework for
B4X developers.

A developer should be able to define a report once and reuse the same
`.b4xr` template in:

-   B4J desktop applications
-   B4J web server applications
-   B4A Android applications
-   HTML output viewed in a browser

The framework should support fixed-layout reports, editable office
documents, and structured data exports. A visual report designer is a
later product layer built on the stable template format and engine.

The goal is a practical B4X reporting framework inspired by the workflow
and capabilities of Crystal Reports, not a claim of complete Crystal
Reports feature parity.

## 2. Product goals

1.  Portable report templates shared across supported B4X targets.
2.  Shared data processing, expression evaluation, grouping,
    aggregation, and layout rules.
3.  Separate visual/document rendering and structured-data export
    pipelines.
4.  Optional output modules and controlled dependencies.
5.  Programmatic report creation in addition to JSON templates.
6.  Native B4J and B4A integration.
7.  B4J server-side generation and browser-compatible HTML output.
8.  A future B4J visual designer that edits the same `.b4xr` files.
9.  A useful public core and a sustainable commercial extension
    strategy.

## 3. Product and licensing proposal

### 3.1 Proposed public components

Proposed MIT-licensed components:

-   B4XReportCore
-   B4XReportLayout
-   B4XReportPDF
-   B4XReportHTML
-   B4XReportCSV
-   B4XReportXML
-   B4XReportJSON
-   Basic B4J and B4A integration adapters, subject to dependency and
    distribution review
-   Examples and core documentation

### 3.2 Proposed commercial components

Separately distributed commercial components:

-   B4XReportDOCX
-   B4XReportXLSX
-   B4XReportODF (ODT and ODS)
-   B4XReportDesigner
-   Premium support and custom integration services

This is the current business proposal. Do not implement license checks,
artificial feature restrictions, or license-server dependencies in the
core engine. The public core must be useful on its own.

Before selecting a third-party library, check: - License and commercial
redistribution rights - Whether source or binary redistribution is
permitted - Java version requirements - B4J compatibility - Android/B4A
compatibility if the dependency is considered for Android - Dependency
size and transitive dependency count - Whether it requires native
binaries or external processes

Do not assume that a Java library suitable for B4J is automatically
suitable for B4A. Record dependency decisions and their rationale in
`docs/dependencies.md`.

## 4. Core architectural requirements

### 4.1 Logical layers

Keep these responsibilities separate:

1.  **Template layer:** parse, validate, version, and serialize `.b4xr`
    templates.
2.  **Data layer:** data-source registration, field access, parameters,
    typed values.
3.  **Processing layer:** sorting, grouping, expressions, aggregates,
    running totals, visibility rules.
4.  **Layout layer:** measure and arrange report elements; paginate
    visual output.
5.  **Intermediate model:** normalized representation consumed by output
    adapters.
6.  **Export/render layer:** PDF, HTML, CSV, XML, JSON, and future
    office formats.
7.  **Platform adapters:** B4J, B4A, and future B4i integration.
8.  **Designer/viewer:** separate applications/components built on
    public APIs.

Do not combine all of these responsibilities into one large class.

### 4.2 Platform independence

The shared core and layout logic must not directly reference: - JavaFX -
Android View, Canvas, Activity, or other Android UI classes - Browser
DOM APIs - B4J server request/response types - Specific database drivers

Use small interfaces or adapter classes for platform-specific operations
such as: - Text measurement - Drawing primitives - Font resolution -
Image loading - File/resource access - Printing - Server response
integration

Avoid leaking platform-specific types through public core APIs.

### 4.3 Coordinate and measurement model

Use a documented physical measurement unit for report geometry. The
initial recommendation is points (1/72 inch), with explicit conversion
utilities for pixels and other units.

Define: - Page dimensions - Orientation - Margins - Element position and
size - Border widths - Font sizes - Image sizing and scaling - Rounding
rules

Do not mix device pixels and physical points without an explicit
conversion.

### 4.4 Rendering and export pipelines

Maintain two related pipelines.

**Visual/document pipeline** - Resolve report data and expressions -
Calculate layout and text measurements - Process sections and groups -
Paginate - Produce a normalized visual/page model - Render or export to
PDF, HTML, and future DOCX/ODT implementations

**Data export pipeline** - Resolve report data and expressions - Apply
applicable sorting, filtering, grouping, and aggregate rules - Produce
normalized columns, rows, and typed values - Export to CSV, XML, JSON,
and future XLSX/ODS implementations

Spreadsheet exporters may use the normalized data model plus
spreadsheet-specific formatting hints. Do not attempt to represent a
spreadsheet as a screenshot or a flattened PDF.

### 4.5 Determinism and safety

-   Do not execute arbitrary B4X, Java, JavaScript, or other code from
    templates.
-   Implement a bounded expression evaluator with a documented grammar.
-   Validate template input and reject invalid or unsupported constructs
    with useful errors.
-   Avoid unsafe file paths when resolving template resources.
-   Define limits or safeguards for recursion, subreports, expression
    complexity, and large input data.
-   Do not silently ignore errors that could result in incomplete
    financial reports.

## 5. Template format (`.b4xr`)

The template is UTF-8 JSON with a `.b4xr` extension. JSON is the
interchange format; the extension identifies a B4XReport template.

The exact schema must be documented in `docs/template-format.md` before
it is treated as stable.

### 5.1 Required schema concepts

The first schema should provide:

-   `schemaVersion`
-   Report ID, name, description, and metadata
-   Page size, orientation, measurement unit, and margins
-   Sections
-   Elements within sections
-   Stable element IDs
-   Data-source declarations
-   Parameters
-   Field references
-   Sorting and grouping declarations
-   Expression definitions
-   Aggregate definitions
-   Basic formatting
-   Conditional visibility/formatting
-   Resource references

### 5.2 Initial section types

At minimum, design for:

-   ReportHeader
-   PageHeader
-   GroupHeader
-   Detail
-   GroupFooter
-   ReportFooter
-   PageFooter

Not every section must be implemented in the first milestone, but the
schema should not make later introduction awkward.

### 5.3 Initial element types

Prioritize:

-   Text/static label
-   Data-bound text field
-   Image
-   Horizontal/vertical line
-   Rectangle
-   Basic border/fill
-   Optional page number and date/time special fields

Each element needs a stable ID, bounds, style, visibility rules, and
type-specific properties.

### 5.4 Schema evolution

-   Include an explicit schema version from the first file.
-   Define compatibility behavior for unknown optional properties.
-   Reject unsupported major versions with a clear diagnostic.
-   Provide migration functions when a future schema change requires
    them.
-   Never change the meaning of an existing property without a
    versioning plan.

### 5.5 Programmatic API

Support both: - Loading and saving `.b4xr` templates - Creating/editing
report definitions programmatically

The programmatic API should manipulate the same underlying report model
used by the JSON loader. Do not create a second, incompatible
report-definition system.

## 6. Data model and sources

### 6.1 Initial data sources

Start with B4X-friendly data structures and a provider abstraction.
Initial support should include practical B4X data such as: - List of
Maps - List of custom objects where reflection/access can be implemented
safely and predictably - Map-based single records and parameters

Do not make a database engine mandatory.

### 6.2 Provider abstraction

Design a data-source interface that can later support: - B4X
collections - SQL query results supplied by the application - REST/API
results - JSON/XML data - Custom application providers - Large or
streamed datasets in a later phase

The report engine should not own database connections or silently
execute arbitrary SQL. Applications should control data access and pass
data/providers to the engine.

### 6.3 Data typing

Preserve values as far as practical: - String - Integer and
floating-point numbers - Decimal/currency values where supported -
Boolean - Date/time - Null/missing

Define culture-aware formatting separately from raw values. CSV/XML/JSON
exporters must have documented null, date, decimal, encoding, and
escaping behavior.

## 7. Initial expression engine

Do not embed a general-purpose scripting engine.

Implement a small, deterministic expression language. Initial
capabilities should include:

-   Field references
-   Parameter references
-   String literals and numeric literals
-   Arithmetic operators
-   Comparison operators
-   Boolean operators
-   Concatenation
-   Parentheses
-   Basic conditional expression
-   Common functions such as `SUM`, `COUNT`, `MIN`, `MAX`, `AVG`, string
    functions, and date formatting as scope permits

Specify null handling, type coercion, evaluation errors, and culture
behavior.

Expression evaluation must be unit-tested. Never use `eval`, dynamic
code compilation, or arbitrary script execution.

## 8. Reporting features by priority

### 8.1 MVP / first useful release

-   Load and validate `.b4xr`
-   Programmatic report construction
-   Page configuration and margins
-   ReportHeader, PageHeader, Detail, ReportFooter, PageFooter
-   Text, data fields, images, lines, rectangles
-   Data binding from List/Map structures
-   Basic sorting
-   Basic expressions and formatting
-   Text wrapping and measurement
-   Multi-page pagination
-   Page numbers
-   PDF export
-   HTML export
-   CSV export
-   XML export
-   JSON export
-   B4J desktop example
-   B4J server example
-   B4A example or a documented B4A integration spike
-   Regression fixtures and sample templates

### 8.2 Next feature set

-   Grouping and nested groups
-   Group headers and footers
-   Subtotals, grand totals, running totals
-   Conditional formatting and visibility
-   Page breaks and keep-together behavior
-   Multiple data sources
-   Browser report viewer
-   B4A rendering/preview integration
-   More robust font and image handling

### 8.3 Advanced features

-   Subreports
-   Charts
-   Cross-tab reports
-   Advanced formula functions
-   Drill-down or interactive HTML reports
-   DOCX and ODT export
-   XLSX and ODS export
-   Visual report designer
-   Template inheritance and reusable styles

## 9. Output-format requirements

### 9.1 PDF

Primary fixed-layout output: - Exact page dimensions and margins - Text
and font handling - Images, lines, and shapes - Repeated headers and
footers - Page numbering - Multi-page reports - Unicode and multilingual
text - Document metadata where feasible

### 9.2 HTML

-   Semantic, accessible HTML where practical
-   CSS generated from report styles
-   Browser preview and printing
-   Support for images and repeated sections
-   Optional responsive behavior
-   No requirement that HTML pagination exactly match PDF pagination in
    every browser

### 9.3 CSV

-   Configurable delimiter, quote, and line ending
-   UTF-8 output and documented optional BOM behavior
-   Correct escaping of delimiters, quotes, and newlines
-   Header inclusion option
-   Culture-independent or explicitly configured numeric/date formatting
-   Null handling
-   Optional selection of fields/columns

### 9.4 XML

-   Well-formed XML
-   Configurable root/row/field naming or a documented default mapping
-   Correct escaping
-   UTF-8
-   Stable null and type representation
-   Optional schema support in a later phase

### 9.5 JSON

-   Valid UTF-8 JSON
-   Stable array/object mapping
-   Correct handling of null and typed values
-   Useful for diagnostics and data interchange

### 9.6 DOCX and ODT

Create editable document structures, not screenshots embedded in a
document. Preserve as much of the report's content and formatting as the
document format allows. Document known fidelity limitations.

### 9.7 XLSX and ODS

Create real worksheets, rows, columns, and typed cells. Support useful
number/date formats, column widths, headers, and multiple sheets as
scope permits. Formulas should be optional and must not be required to
view correct exported values.

## 10. Platform and server integration

### B4J desktop

-   Generate files
-   Preview reports
-   Integrate with desktop printing where practical
-   Avoid making JavaFX a dependency of the shared core

### B4J server

-   Generate output without requiring a desktop UI
-   Provide stream/byte-array output where appropriate
-   Avoid writing temporary files unnecessarily
-   Make it straightforward for the host application to set HTTP content
    type, filename, and response headers
-   Do not couple the engine to a specific B4J web framework

### B4A

-   Reuse templates and shared processing logic
-   Implement Android-specific rendering/preview/printing adapters
    separately
-   Verify all dependencies on an actual supported Android toolchain
-   Do not assume B4J Java libraries are Android-compatible

### Browser

-   Consume generated HTML
-   Provide a lightweight optional viewer component
-   Viewer should support page navigation/zoom/print/download when
    applicable
-   Do not require the browser viewer for server-side PDF or data export

## 11. Milestones and indicative schedule

Estimates assume one primary developer, coding-agent assistance, and
approximately 15--20 hours of focused work per week. These are planning
ranges, not delivery guarantees. The visual designer is excluded from
the initial engine estimate.

  ------------------------------------------------------------------------
  Milestone             Scope                                     Estimate
  --------------------- --------------------- ----------------------------
  M0                    Repository setup,                           1 week
                        architecture          
                        decisions, dependency 
                        audit, schema draft   

  M1                    Core model, JSON                        2--3 weeks
                        parser/serializer,    
                        validation, data      
                        sources               

  M2                    Layout primitives,                      3--4 weeks
                        text measurement      
                        abstraction,          
                        sections, data        
                        binding               

  M3                    Pagination, PDF                         2--3 weeks
                        export, repeat        
                        headers/footers,      
                        regression tests      

  M4                    HTML export and basic                   1--2 weeks
                        browser preview       
                        integration           

  M5                    CSV, XML, JSON                          1--2 weeks
                        exporters             

  M6                    Grouping,                               2--3 weeks
                        expressions,          
                        aggregates, totals,   
                        conditional rules     

  M7                    B4A integration and                     2--3 weeks
                        cross-platform        
                        verification          

  M8                    Documentation,                          1--2 weeks
                        examples, packaging,  
                        release hardening     
  ------------------------------------------------------------------------

**Indicative initial cross-platform engine:** approximately 16--24
weeks, depending on the depth of B4A rendering and the complexity
discovered during pagination and font testing.

DOCX/XLSX/ODT/ODS exporters and the visual designer should be planned as
subsequent work packages. Their estimates should be refined after
dependency and fidelity prototypes.

### Suggested phase gates

-   **Gate A:** A `.b4xr` file can be loaded, validated, and populated
    with data.
-   **Gate B:** A basic one-page report renders correctly.
-   **Gate C:** Multi-page PDF pagination passes regression tests.
-   **Gate D:** The same template produces useful HTML and structured
    exports.
-   **Gate E:** The same report definition works through B4J and B4A
    integration paths.
-   **Gate F:** Public API and schema are stable enough for a 1.0
    release.

## 12. Testing strategy and acceptance criteria

Create automated or repeatable tests from the start.

### Core tests

-   Valid and invalid template parsing
-   Schema-version handling
-   Missing and null fields
-   Parameter resolution
-   Expression parsing and evaluation
-   Sorting and grouping
-   Aggregate calculations
-   Deterministic output from identical inputs

### Layout tests

-   Text wrapping
-   Long text and overflow
-   Font measurement
-   Page boundary conditions
-   Repeated page headers/footers
-   Keep-together and page-break behavior
-   Images and aspect ratios
-   Unicode and multilingual text

### Export tests

-   PDF page count and visual regression fixtures
-   HTML structure and escaping
-   CSV quoting and newline cases
-   XML well-formedness and escaping
-   JSON parsing round-trip
-   DOCX/XLSX/ODF openability when those exporters are implemented

### Cross-platform tests

Use the same sample templates and equivalent data on B4J and B4A.
Compare semantic content and layout within documented tolerances. Do not
demand pixel-identical output where font engines differ.

### MVP acceptance examples

At minimum, deliver these fixtures: 1. One-page invoice with logo, line
items, tax, and totals. 2. Multi-page sales listing with page headers,
page numbers, and a grand total. 3. Grouped sales report with group
subtotals. 4. CSV and XML exports of the same underlying data. 5. HTML
version of the invoice or sales report. 6. B4J server endpoint example
returning a generated PDF. 7. B4A example demonstrating template reuse
and supported output workflow.

A milestone is not complete merely because the code compiles. Its
acceptance tests and examples must pass.

## 13. Coding-agent operating instructions

The coding agent must follow these rules throughout implementation.

1.  Read this document and `README.md` before changing code.
2.  Work milestone by milestone. Do not implement the entire roadmap in
    one pass.
3.  Before each milestone, list the files/modules to be created or
    changed and the acceptance tests to be added.
4.  Do not invent B4X library APIs, classes, or dependencies. Verify
    that every referenced API exists in the target B4X version or mark
    it as an explicit dependency to be validated.
5.  Prefer B4X-native code and collections for shared logic.
6.  Keep B4J and B4A platform-specific code behind adapters.
7.  Do not introduce JavaFX or Android UI dependencies into the shared
    core.
8.  Do not add third-party dependencies without recording version,
    license, platform support, size impact, and reason.
9.  Do not add proprietary/commercial code to the public MIT source
    tree.
10. Do not implement arbitrary code execution in templates.
11. Keep public APIs small and consistent. Document proposed API changes
    before broad implementation.
12. Add tests and examples with each feature; do not defer all testing
    until the end.
13. Avoid premature visual-designer work. The designer must consume the
    same public template model and APIs as applications.
14. Keep documentation synchronized with actual behavior. Mark
    unimplemented features as planned.
15. Do not claim B4A compatibility until the relevant code and
    dependencies have been compiled and tested with B4A.
16. Do not claim an exporter is complete until files have been
    opened/validated by the target format or an appropriate parser.
17. When a requirement is ambiguous, record the decision and trade-off
    in an architecture decision record rather than silently choosing an
    irreversible design.

### Required output at the end of each milestone

-   Implemented source files
-   Tests and test results
-   Updated examples
-   Updated documentation
-   Known limitations
-   Dependency/license changes
-   A short summary of completed acceptance criteria and remaining work

## 14. Initial tasks for the coding agent

Do not begin by implementing every exporter.

Start with M0:

1.  Inspect the available B4X toolchain and target versions.
2.  Propose the repository and module layout.
3.  Draft `docs/architecture.md`.
4.  Draft `docs/template-format.md` with a minimal but extensible
    schema.
5.  Draft `docs/api-design.md` with a B4X-friendly API proposal.
6.  Identify candidate libraries for PDF, DOCX, XLSX, and ODF; audit
    licensing and B4J/B4A compatibility. Do not add them yet.
7.  Define the drawing and text-measurement adapter contracts.
8.  Define a small set of representative report fixtures.
9.  Present decisions, risks, and a milestone-1 implementation plan for
    approval.

After M0 is reviewed, implement M1 only.

## 15. Risks and mitigations

  -----------------------------------------------------------------------
  Risk                                Mitigation
  ----------------------------------- -----------------------------------
  Pagination becomes difficult to     Define layout model and test page
  change                              boundaries early

  B4J and B4A font metrics differ     Abstract measurement and document
                                      tolerances

  Java dependencies fail on Android   Audit early; use platform-specific
                                      implementations where necessary

  Template schema becomes unstable    Version schema and maintain
                                      migration policy

  Exporters produce inconsistent data Share typed data preparation and
                                      define format-specific rules

  Office formats expand scope         Defer office exporters until core
                                      and PDF/HTML are stable

  Visual designer delays engine       Keep designer as a separate later
  release                             milestone

  Large reports exhaust memory        Design provider/streaming extension
                                      points; implement progressively

  Third-party licenses conflict with  Perform license audit before
  distribution                        adopting or bundling dependencies
  -----------------------------------------------------------------------

## 16. Definition of initial 1.0

B4XReport 1.0 should mean:

-   The `.b4xr` schema is documented and versioned.
-   The core API is documented and usable.
-   B4J desktop and B4J server workflows are demonstrated.
-   B4A support has been verified for the features claimed.
-   PDF and HTML visual output work for supported report elements.
-   CSV, XML, and JSON data export are reliable.
-   Multi-page reports and page numbering work.
-   Basic grouping and aggregate functionality is covered by tests.
-   Examples and regression fixtures are included.
-   Dependencies and licenses are documented.
-   Known limitations are explicit.

DOCX, XLSX, ODT, ODS, and the visual designer are planned extensions
unless specifically completed and validated before the 1.0 release.

------------------------------------------------------------------------

## Appendix A --- Initial design principles to preserve

-   One portable template; multiple output targets.
-   B4X-first, not Java-first.
-   B4J-first implementation, but platform-independent core from the
    beginning.
-   Separate visual layout from structured data export.
-   Optional exporters and controlled dependencies.
-   Useful public core; commercial extensions add value without
    crippling the free engine.
-   No dependency on community contributions for project completion.
-   No premature visual designer.
