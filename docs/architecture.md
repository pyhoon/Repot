# Architecture

Status: accepted for M0/M1; M2 layout is in progress. The model, loader,
validator, canonical writer, data binder and render-document types are
implemented in `source/Repot`. The adapter contracts are specified but not
implemented; layout and exporters are not implemented yet.

## 1. Pipeline

```text
          .repot            host data         parameters
             │                  │                  │
             ▼                  ▼                  ▼
     ┌───────────────────────────────────────────────────┐
     │ Template model → Processing (bind/sort/group/agg) │
     └───────────────┬───────────────────────┬───────────┘
                     │                       │
                     ▼                       ▼
              ┌─────────────┐         ┌─────────────┐
              │   Layout    │         │ Data export │
              │ measure and │         │ rows/cells  │
              │  paginate   │         │ typed values│
              └──────┬──────┘         └──────┬──────┘
                     ▼                       ▼
            Render document             CSV / JSON / XML
            (pages of ops)              (and XLSX later)
              │     │     │
              ▼     ▼     ▼
             PDF   HTML  DOCX
```

Two pipelines share data preparation and expression evaluation. They do
not share page geometry. CSV must never inherit margins, and PDF must
never inherit a row cursor.

## 2. Layers and allowed dependencies

| Layer | Responsibility | May depend on |
|-------|----------------|---------------|
| Template | Parse, validate, version, serialise `.repot`; hold the definition model | nothing platform-specific |
| Data | Dataset registration, field resolution, parameters, typed values | template model |
| Processing | Sorting, grouping, aggregates, running totals, visibility, expression evaluation | data, template |
| Layout | Measurement, band arrangement, push-down, pagination | processing, adapters |
| Render document | Immutable page/operation model | layout output only |
| Exporter | Format-specific encoding of the render document or of processed data | render document, processed data, format jars |
| Adapter | Text measurement, fonts, images, resources, printing, file access | platform APIs |

Dependencies point downward. An exporter must not reach into the template
model to re-derive layout. A layout module must not know what PDF is.

## 3. Measurement and units

- Internal geometry unit: **points** (1/72 inch), stored as `Double`.
- Conversion helpers exist for millimetres, inches, and pixels at an
  explicit DPI. There is no implicit DPI.
- Rounding: geometry is rounded half-up to 0.01 pt when drawing
  operations are emitted. Measurement and pagination decisions use the
  unrounded values.
- Font size is in points. Border widths are in points. Image sizing is in
  points.
- Page size, margins, and band heights are expressible in points or
  millimetres in the template; the loader converts to points once.

Never mix device pixels and points in the same value. Device pixels appear
only inside a platform adapter, together with the DPI that produced them.

## 4. Core contracts (conceptual)

These are the adapter contracts layout depends on. They are internal
contracts: B4X has no stable, portable interface mechanism, so a platform
adapter is selected at build time (`ReportB4JAdapter`, later
`ReportB4AAdapter`) and compiled against the same method signatures. The
public API exposes the adapter object, not an abstract base class.

### 4.1 Measurement adapter

```vb
' Returns laid-out lines and the metrics needed for pagination.
Sub MeasureBlock(Text As String, Style As ReportTextStyle, MaxWidth As Double) As ReportTextMetrics
' Width of a single line without wrapping.
Sub MeasureLine(Text As String, Style As ReportTextStyle) As Double
' Nominal line height for the resolved style.
Sub LineHeight(Style As ReportTextStyle) As Double
```

`ReportTextStyle` is a resolved style, not a template style: family, size,
bold, italic, underline, line spacing, and colour. `ReportTextMetrics`
carries `Lines` and `Widths` (one entry per laid-out line), `Width`,
`Height`, `Ascent`, `Descent`, and `LineHeight`. Line breaks are final;
layout does not re-wrap measured text. `Height` is `Lines.Size *
LineHeight`, and `LineHeight` is `font size * line spacing`; platform
leading is reported separately and does not silently change the nominal
line height.

Implemented in M2 slice 1 as `ReportB4JMeasure`, with `ReportTextStyle`,
`ReportTextMetrics` and `ReportFont`. It wraps at spaces and tabs, honours
explicit line breaks, breaks an over-wide word by character, ignores
trailing whitespace, and records a diagnostic if AWT cannot initialise
or a string cannot be measured.

The engine never asks the platform "how does this look"; it asks for
numbers and lays out deterministically from them. A block that exceeds the
maximum line count or depth is rejected with a diagnostic.

### 4.2 Font resolution

```vb
Sub ResolveFont(Family As String, Bold As Boolean, Italic As Boolean, SizePt As Double) As ReportFont
```

`ReportFont` carries `Key` (measurement identity), resolved `Family`,
`Bold`, `Italic`, `Size`, `Ascent`, `Descent`, `LineGap`, and an opaque
`Handle`. Two platforms may return different metrics for the same logical
font; that difference is contained here and documented as a tolerance.

Fallback follows the family list declared in the template's `fonts`
entry, then the platform default. A substitution is reported as a warning
with the requested and chosen family. Falling back silently is forbidden.

`ReportB4JMeasure` implements this for B4J. It measures with public AWT
font APIs at a base size of 1000 pt and scales linearly, because AWT font
sizes are integers and templates may use fractional point sizes. The
resolved family and the `Substituted` flag are recorded on `ReportFont`, so
a layout golden can state which font it actually used.

### 4.3 Image loading

```vb
Sub LoadImage(Path As String, MaxPixels As Long) As ReportImage
```

`ReportImage` carries `Path`, `PixelWidth`, `PixelHeight`, and an opaque
`Handle`. Caching is the adapter's responsibility. Images larger than the
configured pixel limit fail with a diagnostic. The engine needs intrinsic
size and a way to hand the handle to a drawing backend; it does not decode
pixels itself.

### 4.4 Resource resolution

```vb
Sub ResolveResource(Ref As String, BaseDir As String) As String
```

Maps a template resource reference to a readable path. Implementations
must reject absolute paths, `..` escapes, and symlinks that leave the
template's base directory. The normalised result uses `/` separators so
goldens and diagnostics are platform-independent.

### 4.5 PDF canvas

An append-only drawing surface:

```text
BeginPage(width, height)
Text(font, x, y, baseline, text, colour, underline)
Image(handle, x, y, w, h)
Line(x1, y1, x2, y2, width, colour, dash)
Rect(x, y, w, h, strokeWidth, strokeColour, fillColour, radius)
Clip(x, y, w, h) / Restore
Link(x, y, w, h, url, anchorName)   ' optional, ignored by formats without links
EndPage
```

The canvas is deliberately primitive so a future self-contained PDF writer
could implement it without changing layout. Nothing above the canvas knows
about content streams, fonts, or compression.

## 5. Render document

The output of layout is an immutable-by-convention, versioned display
list. The full contract is [render-document.md](render-document.md); the
short form is:

```text
RenderDocument
  Version = 1
  Pages[]
    Index, Width, Height
    Ops[]            text | image | line | rect | clip | restore | link
    Anchors[]        named positions for links/bookmarks
```

Properties:

- Fully resolved. No expressions, no bindings, no dataset references
  remain.
- Deterministic. Same inputs, same operations in the same order.
- Exportable many times. `Build` once, then PDF, HTML, and DOCX from the
  same document.
- Versioned. A schema version exists even though it is internal.
- Geometry rounded to 0.01 pt at emission; text is one operation per
  laid-out line.

Data exports do not use the render document. They consume the processed
data model directly.

## 6. Determinism

Rendering must not consult:

- the wall clock,
- the platform default locale,
- environment variables,
- the filesystem outside declared resources,
- network or database state.

`Now()` is supplied as a parameter. Locale is supplied as a parameter.
Fonts are resolved from a declared font set, with a documented fallback.
Anything that cannot be made deterministic must be exposed as an explicit
input.

Consequence: golden tests are meaningful, and a server can reproduce a
document generated last year.

## 7. Error model

- Parsing and validation produce structured diagnostics with a stable
  code, a JSON pointer or element ID, a message, and severity. The
  registry is [errors.md](errors.md).
- Build fails as a whole or not at all. Never emit a partially correct
  financial document.
- Missing fields resolve to null, not to an error, unless the field is
  declared required.
- Errors surface as `ReportResult.Errors`, not as raw exceptions. The
  public API converts platform exceptions into diagnostics at the adapter
  boundary.
- Warnings (for example, text truncated by a fixed-height element) are
  reported explicitly, never silently swallowed.

## 8. Threading and cancellation

- `Build` and `Export` are resumable subs in B4X terms.
- The engine must be usable from a server handler without a UI thread.
- Cancellation is checked between pages and between detail records.
- Progress reports page count and records processed; no finer granularity
  is promised.
- An engine instance is not shared across concurrent builds. Exporters may
  be reused after `Build` completes.

## 9. Limits

Documented and enforced defaults, all overridable by the application:

- Maximum pages per document.
- Maximum records per dataset.
- Maximum expression nesting depth.
- Maximum sections and elements per report.
- Maximum image pixel dimensions.

Limits exist to fail predictably rather than exhaust memory. They are not
a licensing mechanism.

## 10. Packaging shape

One `.b4xlib` contains the public modules. Exporters are classes inside
it; their jar dependencies are what applications include or omit. See
[decisions/0006-packaging.md](decisions/0006-packaging.md).

## 11. Deliberately excluded

- Database drivers, connection pooling, or query builders.
- Expression compilation to bytecode.
- A plugin system.
- Localisation of report content (values can be formatted per locale;
  translated label text is template data).
- RTL and complex script shaping in 1.0.
- Tagged/accessible PDF in 1.0.

### 4.4 Exporter canvas

The render document is consumed by an exporter through a small canvas
interface. Layout never calls it; exporters do. The B4J implementation
is ReportPdfExporter (PDFBox 2.0); an HTML exporter follows the same
interface.

\\\b
Sub DrawText (X As Double, Y As Double, W As Double, H As Double, Baseline As Double, Text As String, FontName As String, FontSize As Double, Bold As Boolean, Italic As Boolean, Underline As Boolean, Colour As String, Align As String)
Sub DrawImage (X As Double, Y As Double, W As Double, H As Double, ResourcePath As String, PixelWidth As Int, PixelHeight As Int, Dpi As Double, Fit As String, Handle As Object)
Sub DrawLine (X1 As Double, Y1 As Double, X2 As Double, Y2 As Double, LineWidth As Double, Colour As String, Dash As String)
Sub DrawRect (X As Double, Y As Double, W As Double, H As Double, LineWidth As Double, StrokeColour As String, FillColour As String, Radius As Double)
Sub Clip (X As Double, Y As Double, W As Double, H As Double)
Sub Restore
Sub DrawLink (X As Double, Y As Double, W As Double, H As Double, Url As String, AnchorName As String)
\\\

Coordinates are absolute page points in the document's top-down space;
the backend converts to its own origin. Exporters must not re-measure or
re-resolve expressions. PDF targets version 1.7 by default.
