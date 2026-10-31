# Render Document Contract

Status: **version 1, accepted 2026-10-31.** This is the contract every
visual exporter consumes. It is deliberately frozen before layout is
written, because changing it later invalidates goldens and every exporter
at once. See [ADR 0008](decisions/0008-render-document.md).

The definition model, loader, validator and binder exist. The render
document classes exist in `source/Repot`; layout does not produce one yet.

## 1. Purpose

Layout converts a bound, processed report into a flat, fully resolved
display list. Exporters translate that list into PDF, HTML, DOCX, or a
preview surface. Exporters never re-run expressions, re-measure text, or
look at the template.

The contract is:

- **Resolved.** No expressions, bindings, dataset references, or style
  names remain. Values and geometry are final.
- **Deterministic.** Identical inputs produce the same operations in the
  same order on every run.
- **Consumable many times.** Build once, then export to any number of
  formats.
- **Versioned.** The structure has a version even though it is internal.

## 2. Shape

```text
RenderDocument
  Version = 1
  Pages[]
    Index               1-based
    Width, Height       points, full precision
    Ops[]               paint order
    Anchors[]           named positions
```

The implementation is `ReportRenderDocument`, `ReportRenderPage`,
`ReportDrawOp`, and `ReportRenderAnchor`. A document is immutable by
convention after `Build` returns. Layout is the only writer.

Data exports (CSV, JSON, XML) do not use this document. They consume the
processed data model directly.

## 3. Units and rounding

- Geometry is in points (1/72 inch), origin at the top-left of the page,
  y growing downward.
- Page `Width` and `Height` keep full precision, for example A4 is
  `595.2755905511812 × 841.8897637795277`.
- `ReportRenderPage.Add*` rounds every operation coordinate and size
  half-up to **0.01 pt**. Measurement and pagination use unrounded values;
  only emission is rounded.
- Font sizes, line widths, and DPI are not geometry and are not rounded by
  the render document.
- No pixels, device units, or screen DPI appear in the document.

## 4. Operations

`ReportDrawOp` is one flat class. `OpType` selects the meaning; unused
fields keep their initial values. A flat class is used because B4X has no
stable interface or inheritance mechanism for this boundary, and because
the canonical golden writer can serialise it without reflection.

All coordinates are absolute page points, not band-relative.

### 4.1 `text`

One operation per laid-out visual line. Wrapping, alignment, and explicit
newlines have already been resolved.

| Field | Meaning |
|-------|---------|
| `X`, `Y` | Top-left of the line box |
| `Width`, `Height` | Measured line box |
| `Baseline` | Distance from `Y` to the text baseline |
| `Text` | Final line content, trailing whitespace removed |
| `FontName` | Resolved family name |
| `FontSize` | Points |
| `Bold`, `Italic`, `Underline` | Resolved flags |
| `Colour` | `#rrggbb`, empty for the exporter default |
| `Align` | `left`, `center`, or `right`; informational |

`Align` records intent for HTML and future editors. Fixed-layout
exporters position each line from `X` and can ignore it.

### 4.2 `image`

| Field | Meaning |
|-------|---------|
| `X`, `Y`, `Width`, `Height` | Final destination rectangle |
| `ResourcePath` | Normalised path relative to the template folder |
| `PixelWidth`, `PixelHeight` | Intrinsic size of the decoded image |
| `Dpi` | DPI used for `fit: none`, otherwise 0 |
| `Fit` | `contain`, `stretch`, or `none` |
| `Handle` | Opaque in-process image handle; never serialised |

`Handle` is valid for the lifetime of the build process. It is what a PDF
canvas uses. A document that is serialised and reloaded cannot export
images; in-process build-and-export is the supported path.

### 4.3 `line`

| Field | Meaning |
|-------|---------|
| `X`, `Y` | Start point |
| `X2`, `Y2` | End point |
| `LineWidth` | Points |
| `Colour` | `#rrggbb` |
| `Dash` | Empty for solid, otherwise a documented dash name |

A line element's `bounds` `[x, y, w, h]` maps to start `(x, y)` and end
`(x + w, y + h)`. A horizontal rule has `h = 0`.

### 4.4 `rect`

| Field | Meaning |
|-------|---------|
| `X`, `Y`, `Width`, `Height` | Rectangle |
| `LineWidth`, `Colour` | Stroke; empty colour means no stroke |
| `FillColour` | Fill; empty means no fill |
| `Radius` | Corner radius in points |

### 4.5 `clip` and `restore`

`clip` establishes a clip equal to the intersection of the current clip
and the given rectangle. `restore` pops the most recent clip. Pairs must
be balanced within one page. Layout emits clips only when an element's
`overflow` is `clip` or when a partial row is deliberately cut.

### 4.6 `link`

| Field | Meaning |
|-------|---------|
| `X`, `Y`, `Width`, `Height` | Clickable rectangle |
| `Url` | External target, or empty |
| `AnchorName` | Internal target, or empty |

Exactly one of `Url` and `AnchorName` is non-empty. Exporters may ignore
links; PDF and HTML are expected to honour them. A link operation does
not draw anything.

## 5. Fonts and colours

- Text operations carry resolved font identity, not a style reference.
- `FontName` is the family the measurement adapter actually used after
  fallback. The exporter must resolve the same family. If it cannot, it
  substitutes and records the substitution.
- Measurement identity keys (font file, hinting, rasteriser) are not part
  of the document; they are a layout concern and a fidelity tolerance.
- Colours are normalised to `#rrggbb`. Alpha is not in version 1.
- An empty colour means "use the exporter's default", which is black for
  text and stroke, and no fill for rectangles.

## 6. Pages, ordering, and anchors

- Pages are ordered; `Index` starts at 1 and is contiguous.
- `Ops` array order is paint order. Later operations paint over earlier
  ones.
- Layout sorts elements by `z` (ascending), then document order, then
  emits text lines top to bottom. Ties in `z` keep document order.
- Anchors are named positions, in points. Anchor names are unique across
  the document. `link.anchorName` refers to an anchor name.
- A page always has a positive width and height. Page count is
  `Pages.Size`.

## 7. Canonical form and goldens

Layout goldens compare the canonical JSON form, not pixels. The planned
writer (M3) produces:

```json
{
  "version": 1,
  "pages": [
    {
      "index": 1,
      "width": 595.2756,
      "height": 841.8898,
      "ops": [
        { "type": "text", "x": 42.52, "y": 51.02, "width": 120.00,
          "height": 10.80, "baseline": 8.60, "text": "INVOICE",
          "font": "DejaVu Sans", "size": 18.00, "bold": true,
          "italic": false, "underline": false, "colour": "#000000",
          "align": "left" }
      ],
      "anchors": []
    }
  ]
}
```

Rules:

- Object keys are emitted in a fixed order, not map order.
- Page dimensions use four decimal places; operation geometry uses two.
- Empty optional strings and zero optional numbers are omitted.
- `Handle` is never written.
- No timestamps, absolute paths, or platform identifiers appear.
- The same document serialised twice produces identical bytes.

## 8. Versioning

- The current version is `1`.
- Additive fields that old exporters can ignore may keep version 1 only
  if the omission is harmless. Otherwise the version is bumped.
- A breaking change requires an ADR, a golden regeneration, and a note in
  the release migration table.
- The template `schemaVersion` and the render document `Version` are
  independent.

## 9. Not in version 1

- Gradients, patterns, transparency groups, and blend modes.
- Rich text runs inside one line; each line has one font.
- Vector paths other than lines and rectangles.
- Embedded fonts or font bytes.
- Shading, images as masks, or image clipping other than rectangular
  clips.
- Semantic structure for tagged PDF or accessibility.
- Interactive widgets other than links.
