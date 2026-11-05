# Repot Tutorial for B4X Developers

Repot is a cross-platform reporting and document-generation engine for the
B4X ecosystem (B4J desktop/server, B4A Android). Written in B4X and licensed
MIT, it turns a portable report definition (`.repot` JSON) plus data supplied
by your application into paginated PDF, HTML, and office documents
(DOCX, XLSX, ODT, ODS) plus structured data exports (CSV, JSON, XML).

This tutorial walks through an end-to-end invoice report, then covers each
capability in detail.

---

## 1. Installation

### Add the library

Repot ships as a source-only `.b4xlib` (a zip of `.bas` modules). In your
B4J or B4A project:

1. Copy `dist/Repot.b4xlib` (from the Repot repo or a release) into your
   project's **Additional Libraries** folder (`%Additional%\B4J` or
   `%Additional%\B4A`).
2. In the IDE, add a reference to **Repot**.

### B4J PDF dependency (PDF only)

If you export PDF on B4J, Repot uses Apache PDFBox 3.0.8. It is **not**
bundled in the `.b4xlib`; place `pdfbox-app-3.0.8.jar` (Maven Central,
Apache-2.0) in your Additional Libraries folder and add it as a library
reference in the IDE. B4A uses the built-in Android Printing library and
needs nothing extra.

---

## 2. Your first report (end-to-end)

We'll build a one-page invoice: header, line-item table, totals, and page
footer. Then export it to PDF, HTML, and XLSX.

### Step A: Write the template (`invoice.repot`)

Save this next to your app (or bundle it as a file asset):

```json
{
  "schemaVersion": "0.1",
  "id": "invoice.standard",
  "name": "Standard invoice",
  "page": {
    "size": "A4",
    "orientation": "portrait",
    "margins": { "top": "12mm", "right": "15mm", "bottom": "18mm", "left": "15mm" }
  },
  "fonts": {
    "body": { "family": ["DejaVu Sans", "Arial", "sans-serif"], "size": 9 }
  },
  "styles": {
    "title": { "font": "body", "size": 18, "bold": true },
    "label": { "font": "body", "colour": "#555555" },
    "cell": { "font": "body", "valign": "middle", "overflow": "grow" },
    "cellRight": { "font": "body", "align": "right", "valign": "middle", "overflow": "grow" },
    "totalValue": { "font": "body", "size": 11, "bold": true, "align": "right", "overflow": "grow" }
  },
  "parameters": [
    { "name": "ReportTitle", "type": "string", "required": true }
  ],
  "dataSets": [
    {
      "name": "Items",
      "kind": "rows",
      "fields": [
        { "name": "Description", "type": "string" },
        { "name": "Quantity", "type": "decimal", "format": { "type": "number", "decimals": 0 } },
        { "name": "UnitPrice", "type": "decimal", "format": { "type": "number", "decimals": 2, "grouping": true } },
        { "name": "Amount", "type": "decimal", "format": { "type": "number", "decimals": 2, "grouping": true } }
      ]
    }
  ],
  "sections": [
    {
      "type": "ReportHeader",
      "id": "report-header",
      "height": 40,
      "elements": [
        { "type": "field", "id": "title", "bounds": [0, 0, 400, 24], "style": "title", "value": "{param.ReportTitle}" },
        { "type": "text", "id": "subtitle", "bounds": [0, 26, 500, 14], "style": "label", "text": "Northwind Traders - Invoice" }
      ]
    },
    {
      "type": "PageHeader",
      "id": "page-header",
      "height": 20,
      "elements": [
        { "type": "text", "id": "hdr-desc", "bounds": [0, 0, 300, 16], "style": "label", "text": "Description" },
        { "type": "text", "id": "hdr-qty", "bounds": [300, 0, 80, 16], "style": "label", "text": "Qty" },
        { "type": "text", "id": "hdr-price", "bounds": [380, 0, 100, 16], "style": "label", "text": "Unit Price" },
        { "type": "text", "id": "hdr-amount", "bounds": [480, 0, 100, 16], "style": "label", "text": "Amount" }
      ]
    },
    {
      "type": "Detail",
      "id": "detail",
      "dataSet": "Items",
      "height": 16,
      "elements": [
        { "type": "field", "id": "cell-desc", "bounds": [0, 0, 300, 16], "style": "cell", "value": "{Description}" },
        { "type": "field", "id": "cell-qty", "bounds": [300, 0, 80, 16], "style": "cellRight", "value": "{Quantity}" },
        { "type": "field", "id": "cell-price", "bounds": [380, 0, 100, 16], "style": "cellRight", "value": "{UnitPrice}" },
        { "type": "field", "id": "cell-amount", "bounds": [480, 0, 100, 16], "style": "cellRight", "value": "{Amount}" }
      ]
    },
    {
      "type": "ReportFooter",
      "id": "report-footer",
      "height": 24,
      "elements": [
        { "type": "text", "id": "total-label", "bounds": [380, 0, 100, 14], "style": "label", "text": "Total:" },
        { "type": "field", "id": "total-value", "bounds": [480, 0, 100, 14], "style": "totalValue", "value": "{param.GrandTotal}" }
      ]
    },
    {
      "type": "PageFooter",
      "id": "page-footer",
      "height": 24,
      "elements": [
        { "type": "field", "id": "page-no", "bounds": [0, 8, 200, 12], "style": "label", "value": "Page {page.number} of {page.count}" }
      ]
    }
  ]
}
```

Key ideas:
- `dataSets.Items` declares the columns your detail rows will have.
- `sections.Detail` has `dataSet: "Items"` — one band per data row.
- `{param.ReportTitle}` and `{param.GrandTotal}` are parameter expressions.
- `{Description}`, `{Quantity}` etc. are field expressions bound to each row.
- `page.number` / `page.count` are built-in page fields.

### Step B: Host code (B4J example)

```b4x
' Process_Globals or wherever you keep your report object
Dim repot As Repot
repot.Initialize

' 1. Load the template
If repot.LoadTemplate(File.DirApp, "invoice.repot") = False Then
    Log("Template errors: " & repot.Diagnostics.Errors)
    Return
End If

' 2. Set parameters
repot.SetParameter("ReportTitle", "INVOICE #1024")
repot.SetParameter("GrandTotal", 2449.95)

' 3. Bind data (one row per item)
Dim items As List
items.Initialize
Dim row1 As Map
row1.Initialize
row1.Put("Description", "Annual support, standard tier")
row1.Put("Quantity", 1)
row1.Put("UnitPrice", 1200)
row1.Put("Amount", 1200)
items.Add(row1)

Dim row2 As Map
row2.Initialize
row2.Put("Description", "On-site installation and configuration")
row2.Put("Quantity", 2)
row2.Put("UnitPrice", 175)
row2.Put("Amount", 350)
items.Add(row2)

repot.SetDataSource("Items", items)

' 4. Build the render document (layout + pagination)
Dim result As ReportResult = repot.Build
If result.Success = False Then
    Log("Build errors: " & result.Errors)
    Return
End If
Log("Pages: " & result.PageCount & ", Records: " & result.RecordCount)

' 5. Export to any format
repot.ExportPdf(File.Combine(File.DirApp, "invoice.pdf"))
repot.ExportHtml(File.Combine(File.DirApp, "invoice.html"))
repot.ExportXlsx(File.Combine(File.DirApp, "invoice.xlsx"))
repot.ExportOds(File.Combine(File.DirApp, "invoice.ods"))
repot.ExportDocx(File.Combine(File.DirApp, "invoice.docx"))
repot.ExportCsv(File.Combine(File.DirApp, "items.csv"))
repot.ExportJson(File.Combine(File.DirApp, "items.json"))
repot.ExportXml(File.Combine(File.DirApp, "items.xml"))
```

### B4A differences

B4A code is nearly identical. Two things differ:

- **File paths:** use `File.DirInternal` or the SAF (Storage Access Framework) for user-chosen locations, not `File.DirApp`.
- **PDF:** uses Android's Printing library (no PDFBox jar needed).
- **Printing:** `repot.PrintPdf(dir, fileName, jobName)` opens the system print dialog on B4A.

---

## 3. Template format deep dive

A `.repot` file is JSON. The major sections:

| Section | Purpose |
|---------|---------|
| `page` | Size, orientation, margins, optional grid |
| `fonts` | Named font families with fallbacks (by name, not file path) |
| `styles` | Reusable style blocks referenced by elements |
| `parameters` | Values supplied by the host at runtime (`{param.Name}`) |
| `dataSets` | Column declarations with optional field-level display `format` |
| `sections` | ReportHeader, PageHeader, GroupHeader, Detail, GroupFooter, PageFooter, ReportFooter |
| `elements` | text, field, image, line, rect inside each section |

### Expressions

Values in `field` elements use braces:

| Expression | Source |
|------------|--------|
| `{param.ReportTitle}` | Parameter set via `SetParameter` |
| `{Description}` | Current row field from the Detail dataset |
| `{page.number}` / `{page.count}` | Built-in pagination fields |

### Field-level display format (v1.7+)

Dataset fields may carry an optional `format` object. It controls how numbers
and dates appear in **office exports** (XLSX/ODS). Layout (PDF/HTML) ignores
it.

```json
{ "name": "Amount", "type": "decimal",
  "format": { "type": "number", "decimals": 2, "grouping": true } }
```

Supported format keys: `type` (`number`, `date`, `text`, `boolean`),
`decimals`, `grouping`, `prefix`, `suffix`, `pattern`, `trueText`,
`falseText`. Defaults follow the declared type when absent
(`decimal` → `0.00`, `date` → `yyyy-MM-dd`, etc.).

---

## 4. Loading, validation, and diagnostics

```b4x
repot.Initialize
If repot.LoadTemplate(File.DirApp, "invoice.repot") = False Then
    ' Template failed to parse or validate
    For Each err As String In repot.Diagnostics.Errors
        Log("ERROR: " & err)
    Next
    For Each warn As String In repot.Diagnostics.Warnings
        Log("WARNING: " & warn)
    Next
    Return
End If
```

`LoadTemplate` returns `False` on parse/validation errors. `Diagnostics`
holds both errors and warnings. After `Build`, check `result.Success` and
`result.Errors`.

---

## 5. Binding data

| Method | Use |
|--------|-----|
| `SetParameter(Name, Value)` | Scalar report values (`{param.Name}`) |
| `SetParameterInt/Double/Bool/Date` | Typed parameters |
| `SetDataSource("Items", listOfMaps)` | Detail rows (`Kind = "rows"`) |
| `SetDataSourceSingle("Customer", singleMap)` | Single-record dataset (`Kind = "single"`) |

Each map key must match a declared field name. Missing fields become `Null`
(empty cells). Extra keys in the data are ignored with a warning.

Dates should be ISO strings (`yyyy-MM-dd`, `yyyy-MM-dd HH:mm:ss`) or B4X
ticks. Booleans become native boolean cells in XLSX/ODS.

---

## 6. Building once, exporting many times

`Build` runs layout + pagination once and stores the render document.
You can then call any number of `Export*` methods without re-layout:

```b4x
Dim result As ReportResult = repot.Build
If result.Success Then
    repot.ExportPdf(File.Combine(File.DirApp, "invoice.pdf"))
    repot.ExportHtml(File.Combine(File.DirApp, "invoice.html"))
    repot.ExportXlsx(File.Combine(File.DirApp, "invoice.xlsx"))
End If
```

This is useful when you want the same layout in multiple formats, or when
you need to inspect `result.PageCount` / `result.RecordCount` before
deciding what to export.

---

## 7. Format-specific notes

### PDF (B4J via PDFBox, B4A via Printing)

- B4J: embeds TrueType fonts; set `repot.FontFile` / `FontFileBold` and
  `repot.AddEmbeddedFont(reg, bold)` for mixed scripts (CJK, Arabic,
  Hebrew). Without registered covering fonts, unsupported glyphs become `?`.
  Requires `pdfbox-app-3.0.8.jar` in Additional Libraries.
- B4A: vector PDF through the Android Printing library; no external jar.
- `GetPdfPageCount(path)` and `ExtractPdfText(path)` (B4J only) let you
  introspect exported files.

### HTML

- `ExportHtml` writes a fixed-layout document with explicit page boxes.
- `GetHtml` returns the HTML string for inline preview (e.g. in a WebView).
- B4A can print HTML via `PrintHtml(jobName)`.

### XLSX / ODS (v1.7 typed cells)

Cells are typed: numbers as numbers, dates as serials/ISO dates, booleans
as booleans. Field `format` controls decimals/grouping/prefix/suffix.
Column widths come from formatted text. `=SUM(D2:D5)` works out of the box
in Excel.

### DOCX / ODT

Word processing documents. All cells are text (documents have no cell type).

### CSV / JSON / XML

Structured data exports of the default dataset (or a named dataset via the
`...Of` variants).

---

## 8. Fonts and multi-language (CJK, Arabic, Hebrew)

Repot resolves fonts **by name** through the platform's font stack. Users
do **not** need to install fonts to run the library, but PDF output will
show `?` for glyphs not covered by any registered font.

For B4J PDF with CJK/Arabic/Hebrew:

1. Bundle a covering TTF with your app (e.g. Noto Sans SC subset, Noto Sans
   Arabic, Noto Sans Hebrew — all SIL OFL 1.1).
2. Declare the family in the template:
   ```json
   "fonts": { "body": { "family": ["Noto Sans SC", "DejaVu Sans", "sans-serif"], "size": 9 } }
   ```
3. Register the TTF in host code before `ExportPdf`:
   ```b4x
   repot.FontFile = File.Combine(assetsDir, "NotoSans-Regular.ttf")
   repot.FontFileBold = File.Combine(assetsDir, "NotoSans-Bold.ttf")
   repot.AddEmbeddedFont(File.Combine(assetsDir, "NotoSansSC-Subset-Regular.ttf"), File.Combine(assetsDir, "NotoSansSC-Subset-Regular.ttf"))
   repot.Build
   repot.ExportPdf(File.Combine(File.DirApp, "report.pdf"))
   ```

RTL (Arabic/Hebrew) is shaped and reordered automatically; set
`repot.BaseDirection = "rtl"` for RTL-base paragraphs.

> Fonts are embedded **at generation time**. The viewing host needs nothing
> installed — but the generating host must have the TTF and register it, or
> non-Latin glyphs become `?`.

---

## 9. B4A-specific: printing and Save As

On Android, use the system print dialog:

```b4x
' After ExportPdf to a temp file
repot.PrintPdf(File.DirInternal, "invoice.pdf", "Invoice #1024")
```

For user-chosen locations (SAF):

```b4x
Dim intent As Object = repot.SaveAsPdfIntent("application/pdf", "Invoice.pdf")
' Launch the intent and handle the result URI in Activity_Result
```

---

## 10. Complete minimal B4J example

```b4x
#Region Project Attributes
#MainFormWidth = 600
#MainFormHeight = 400
#End Region

Sub Process_Globals
    Dim repot As Repot
End Sub

Sub AppStart (Args() As String)
    repot.Initialize

    ' Load template
    If repot.LoadTemplate(File.DirApp, "invoice.repot") = False Then
        Log("Template load failed: " & repot.Diagnostics.Errors)
        Return
    End If

    ' Parameters
    repot.SetParameter("ReportTitle", "INVOICE #1024")
    repot.SetParameter("GrandTotal", 2449.95)

    ' Data
    Dim items As List
    items.Initialize
    Dim r1 As Map
    r1.Initialize
    r1.Put("Description", "Annual support, standard tier")
    r1.Put("Quantity", 1)
    r1.Put("UnitPrice", 1200)
    r1.Put("Amount", 1200)
    items.Add(r1)

    Dim r2 As Map
    r2.Initialize
    r2.Put("Description", "On-site installation")
    r2.Put("Quantity", 2)
    r2.Put("UnitPrice", 175)
    r2.Put("Amount", 350)
    items.Add(r2)

    repot.SetDataSource("Items", items)

    ' Build + export
    Dim result As ReportResult = repot.Build
    If result.Success = False Then
        Log("Build failed: " & result.Errors)
        Return
    End If

    repot.ExportPdf(File.Combine(File.DirApp, "invoice.pdf"))
    repot.ExportXlsx(File.Combine(File.DirApp, "invoice.xlsx"))
    Log("Done. Pages: " & result.PageCount)
End Sub
```

---

## 11. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `LoadTemplate` returns False | Template JSON invalid, missing dataset, unknown style | Check `Diagnostics.Errors` |
| `Build` returns `Success = False` | Binder validation: dataset not supplied, required parameter missing | Call `SetDataSource` / `SetParameter` for every declared dataset/parameter |
| PDF shows `?` for CJK | No covering TTF registered | Register font via `FontFile` / `AddEmbeddedFont` |
| Excel opens XLSX with repair prompt | (Fixed in v1.7) | Upgrade to Repot 1.7.0 |
| B4A PDF fails | Missing `Printing` library reference | Add `Printing` to the B4A project libraries |
| `page.number` / `page.count` empty | Used outside PageFooter/ReportFooter | Page fields only resolve in page-context sections |

---

## 12. Version and support

- Current: **v1.7.0** (typed XLSX/ODS cells, field display formats)
- Previous: v1.6.0 (inline HTML preview, viewport meta, B4A Save As fix)
- License: MIT. Fonts in `fixtures/_fonts/` are SIL OFL 1.1 (test only).
- Issues: report template/engine bugs against the `.repot` schema; font
  embedding questions belong in your host application's font bundling.
