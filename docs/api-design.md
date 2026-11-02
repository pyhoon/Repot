# API Design

Status: proposal for the unified `Repot` facade. The underlying modules it
would wrap are shipped: template model, loader, validator, data binder,
measurement adapter, band layout, paginator, render-document types, and
the PDF/HTML/CSV/JSON/XML/DOCX/XLSX exporters (M1-M9). The facade itself
is not implemented; consumers use the modules directly (see
`examples/`). Names are not yet frozen.

## 1. Principles

1. **Small surface.** A developer should be able to generate a report
   after reading one page.
2. **Two phases.** Build once, export many. Layout is expensive; PDF and
   HTML must not each re-run it.
3. **Explicit inputs.** Clock, locale, fonts, and data are passed in.
   Nothing is read from the environment.
4. **Fail loud.** No silently incomplete documents. Diagnostics come back
   in the result, not as platform exceptions.
5. **B4X idiom first.** No generics, no lambdas, no optional parameters,
   no method overloading (B4X does not support them). Where .NET-style
   API would use overloads, provide named variants.
6. **No platform leakage.** Public signatures use only B4X types: `Map`,
   `List`, `String`, `Int`, `Double`, `Boolean`, `Long`, `Object`.

## 2. The facade

```vb
Dim Report As Repot
Report.Initialize
Report.LoadTemplate(File.DirAssets, "Invoice.repot")
Report.SetDataSource("Items", LineItems)          ' List
Report.SetDataSourceSingle("Customer", Customer)  ' Map
Report.SetParameter("InvoiceNumber", "INV-1042")
Report.SetParameterDate("IssuedOn", DateTime.Now)
Report.SetTimestamp(Now)        ' explicit clock for date/time fields
Report.SetLocale("en-GB")       ' explicit culture for formatting

Wait For (Report.Build) Complete (Result As ReportResult)
If Result.Success = False Then
    For Each D As ReportDiagnostic In Result.Errors
        Log(D.Code & " " & D.ElementId & ": " & D.Message)
    Next
    Return
End If
```

`Build` performs parse, bind, process, layout, and returns a reusable
result. `Result` is immutable.

Named variants exist because B4X lacks overloads:

| Method | Purpose |
|--------|---------|
| `SetParameter(Name, Value)` | String or object parameter |
| `SetParameterInt`, `SetParameterDouble`, `SetParameterBool`, `SetParameterDate` | Typed parameters |
| `SetDataSource(Name, List)` | Row dataset |
| `SetDataSourceSingle(Name, Map)` | Single-record dataset |
| `SetDataSourceProvider(Name, Provider)` | Streaming/lazy provider |
| `SetTimestamp(Ticks)` | Clock used by date/time fields |
| `SetLocale(Tag)` | Culture for number/date formatting |
| `SetLimits(Limits)` | Page/record/depth limits |
| `Cancel` | Cooperative cancellation between pages/records |

## 3. Result

```vb
Result.Success As Boolean
Result.Errors As List              ' ReportDiagnostic
Result.Warnings As List
Result.PageCount As Int
Result.RecordCount As Int
Result.DurationMs As Long
Result.SourceVersion As String     ' schemaVersion of the template
```

`ReportDiagnostic`: `Severity`, `Code`, `Message`, `ElementId`,
`Path` (JSON pointer), `Hint`. Codes are stable strings such as
`E-TPL-104` and are listed in the docs as they are introduced.

The result also carries the render document, but as an opaque handle.
Applications do not read it; exporters do. Its version 1 structure is
specified in [render-document.md](render-document.md). The classes are
public so exporters can be written outside the core, but the contract is
for exporters, not for application code.

## 4. Exporters

Each exporter is a class with the same shape:

```vb
Dim Pdf As ReportPdf
Pdf.Initialize(Result)
Pdf.SetOption("title", "Invoice 1042")
Pdf.SetOption("compress", "true")
Wait For (Pdf.ExportToFile(File.DirApp, "invoice.pdf")) Complete (Ok As Boolean)
If Ok = False Then Log(Pdf.LastError.Message)
```

```vb
Wait For (Html.ExportToString) Complete (Html1 As String)
Wait For (Csv.ExportToStream(Out)) Complete (Ok As Boolean)
```

Rules:

- Exporters never re-run expressions or layout.
- Exporters have no knowledge of template structure, only the render
  document (visual) or processed data (CSV/JSON/XML).
- Format-specific options are string-keyed and documented per exporter.
  Unknown options produce a warning, not an error.
- `LastError` is populated on failure; `ExportTo*` returns `False`
  instead of raising for expected failures.

Planned classes: `ReportPdf`, `ReportHtml`, `ReportCsv`,
`ReportJson`, `ReportXml`, `ReportDocx`, later
`ReportXlsx`.

Two HTML modes are selected by option, not by class:

```vb
Html.SetOption("mode", "layout")   ' faithful, absolutely positioned
Html.SetOption("mode", "flow")     ' semantic, responsive (v0.2)
```

## 5. Data providers

For large datasets the application supplies a provider instead of a List.
A provider is a class implementing three subs:

```vb
Public Sub Reset
Public Sub Close
Public Sub NextRecord As Map      ' return Null when exhausted
```

The engine pulls records, so the application keeps control of paging,
streaming, and connection lifetime. The engine never opens a connection
and never sees SQL.

Responsibilities are explicit: the provider returns typed values with the
field names declared in the template. Unknown fields are a diagnostic;
missing fields are null.

## 6. Programmatic construction

The same in-memory definition that the JSON loader produces is available
for construction, so there is no second report model:

```vb
Dim Def As ReportDefinition = Report.NewDefinition("invoice.programmatic")
Def.SetPageSize("A4", "portrait")
Def.SetMargins(12, 15, 18, 15, "mm")
Def.AddDataSet("Items", "Item, Quantity, Amount")
Def.AddStyle("cell", "Arial", 9)
Dim S As ReportSection = Def.AddSection("Detail", "Items")
S.SetHeight(16)
S.AddField("desc", 0, 0, 240, 16, "{Description}", "cell")
S.AddField("amt", 410, 0, 100, 16, "{Amount}", "money")
Report.SetDefinition(Def)
```

The builder writes the same structures as the loader. Serialising a
programmatically built report to `.repot` must round-trip through the
loader, and that round-trip is a test.

## 7. Adapters and initialisation

Platform behaviour is injected once, at the edge:

```vb
Dim Adapter As ReportB4JAdapter   ' or ReportB4AAdapter
Adapter.Initialize
Report.SetAdapter(Adapter)
```

The adapter supplies text measurement, font resolution, image loading,
resource resolution, and the drawing backend used by exporters. An
adapter may be constructed with explicit font directories and a DPI, and
must never read global UI state.

A headless server uses the B4J adapter with no JavaFX initialisation. If
a backend genuinely requires JavaFX, that is a bug in the adapter, not a
reason to leak JavaFX into the core.

## 8. Threading contract

- `Build`, `ExportToFile`, `ExportToStream`, and `ExportToString` are
  resumable subs and must be called with `Wait For`.
- The engine does not require a UI thread. It must not touch views.
- One `Repot` instance is used by one build at a time. The result may
  be exported concurrently to different formats, provided each exporter
  has its own instance.
- Cancellation is cooperative and checked between records and pages.

## 9. Compatibility promises

- Public class and method names are stable within a major version.
- New features are additive. Existing signatures do not change within a
  major version.
- Deprecation: mark, document, keep for one minor cycle, remove at the
  next major.
- The template `schemaVersion` and the library version are independent.
  A library may support several schema versions.

## 10. Deliberately not in the API

- Direct access to layout internals or page operations (exporters aside).
- A callback per element or per page during layout (would break
  determinism and two-pass numbering).
- Template mutation after `Build`.
- Anything named `Sql`, `Query`, `Connection`, or `Database`.
- A licence, activation, or telemetry entry point. There will not be one.
