# Architecture

Status: draft for M0 review. This document defines responsibilities and
contracts. It does not describe implemented code.

## 1. Pipeline

```text
          .b4xr            host data         parameters
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
| Template | Parse, validate, version, serialise `.b4xr`; hold the definition model | nothing platform-specific |
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

These are shapes, not final signatures. Signatures are frozen in M1.

### 4.1 Measurement adapter

```vb
' Returns the number of whole lines and the metrics needed for layout.
Sub MeasureBlock(Text As String, Style As RepotTextStyle, MaxWidth As Double) As RepotTextMetrics
' Width of a single line without wrapping.
Sub MeasureLine(Text As String, Style As RepotTextStyle) As Double
' Nominal line height for the style.
Sub LineHeight(Style As RepotTextStyle) As Double
```

`RepotTextMetrics` carries `LineCount`, `Width`, `Height`, and the
break positions used. The engine never asks the platform "how does this
look"; it asks for numbers and lays out deterministically from them.

### 4.2 Font resolution

`Resolve(Name, Bold, Italic, SizePt) As RepotFont` returns an opaque
font handle plus a measurement identity string. Two platforms may return
different metrics for the same logical font; that difference is contained
here and documented as a tolerance.

### 4.3 Image loading

`Load(ResourceRef) As RepotImage` returns pixel dimensions and an
opaque handle. Caching is the adapter's responsibility. The engine only
needs intrinsic size and a way to hand the handle to a drawing backend.

### 4.4 Resource resolution

`Resolve(Ref, BaseDir) As String` maps a template resource reference to a
readable path or identifier. Implementations must reject paths that escape
the template's base directory.

### 4.5 PDF canvas

An append-only drawing surface:

```text
BeginPage(width, height)
Text(font, x, y, text)
Image(handle, x, y, w, h)
Line(x1, y1, x2, y2, width, colour, dash)
Rect(x, y, w, h, stroke, fill, radius)
Clip(x, y, w, h) / Restore
Link(x, y, w, h, url)        ' optional, ignored by formats without links
EndPage
```

The canvas is deliberately primitive so a future self-contained PDF writer
could implement it without changing layout. Nothing above the canvas knows
about content streams, fonts, or compression.

## 5. Render document

The output of layout is an immutable document:

```text
RenderDocument
  Pages[]            one per physical page
    Width, Height, Index
    Ops[]            text run | image | line | rect | clip | link
    Anchors[]        optional named positions for links/bookmarks
```

Properties:

- Fully resolved. No expressions, no bindings, no dataset references
  remain.
- Deterministic. Same inputs, same bytes of structure.
- Exportable many times. `Build` once, then PDF, HTML, and DOCX from the
  same document.
- Versioned. A schema version exists even though it is internal.

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
  code, a JSON pointer or element ID, a message, and severity.
- Build fails as a whole or not at all. Never emit a partially correct
  financial document.
- Missing fields resolve to null, not to an error, unless the field is
  declared required.
- Errors surface as `RepotResult.Errors`, not as raw exceptions. The
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
