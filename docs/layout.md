# Layout Model

Status: accepted 2026-10-31; M2 implementation is in progress. The layout
model is the most expensive thing in this project to change later. Read
this before touching the schema or the engine.

## 1. Coordinate system

- Origin is the top-left of the physical page.
- Units are points (1/72 inch). Y grows downward.
- The page box is `0,0,pageWidth,pageHeight`.
- Margins carve a content box: `marginLeft, marginTop, pageWidth -
  marginRight, pageHeight - marginBottom`.
- Bands occupy the full content width. A band's children are positioned
  relative to the band's top-left, not the page.
- Band heights are inclusive of the band's own padding.

Pixels exist only inside platform adapters, always paired with an
explicit DPI. A template never contains pixels.

## 2. Why bands, not a page of free-floating elements

Reports are repetitive documents: one detail row per record, repeated
headers, totals after groups. A page-of-elements model forces the engine
to invent those repetitions. Bands make repetition a first-class concept
and make pagination expressible.

The section catalogue for 1.0:

| Section | Emitted | Auto-grow |
|---------|---------|-----------|
| ReportHeader | once, first page | yes |
| PageHeader | every page | no (fixed height) |
| GroupHeader | per group, and again after a page break inside the group | yes |
| Detail | per record | yes |
| GroupFooter | per group | yes |
| PageFooter | every page | no (fixed height) |
| ReportFooter | once, last page | yes |

PageHeader and PageFooter are fixed height by design: a header that grows
mid-document makes the content box unstable and page counts
non-deterministic. If a header needs more room, it is a layout error, not
a growth opportunity.

## 3. Positioning: bounds or grid cells

A band child may be positioned in two ways. The loader normalises both
into points; layout and exporters only ever see points.

**Absolute**

```json
{ "type": "text", "id": "lbl-title", "bounds": [0, 0, 240, 18], ... }
```

**Grid cell**

```json
{ "type": "text", "id": "lbl-title", "cell": { "col": 0, "row": 0, "colSpan": 6, "rowSpan": 1 }, ... }
```

The optional page-level grid defines cell size either explicitly or by
column/row counts:

```json
"grid": { "cellWidth": 14.17, "cellHeight": 11.0 }
"grid": { "columns": 40, "rows": 27 }
```

Rules:

- `columns`/`rows` are resolved against the content box to
  `cellWidth`/`cellHeight`. If both forms are present, explicit sizes win.
- Grid cells are uniform in each axis. They are *not* required to be
  square, and a template that assumes square cells on A4 is a template
  bug. (A 40×27 grid over A4 gives 5.25 pt × 11 pt cells, which is
  visibly anisotropic. This trap is taken from prior art; see
  [prior-art.md](prior-art.md).)
- Cell geometry is `x = col * cellWidth`, `width = colSpan * cellWidth`,
  and likewise vertically.
- Mixing `bounds` and `cell` in the same band is allowed, but a band
  should pick one convention. The designer UI enforces one at a time; the
  loader does not.
- Elements may overlap. Overlap is allowed on purpose (watermark, rules
  behind text) and paint order is document order.

Grid is a convenience for editors and humans. It is not a constraint
engine, and the engine will not police alignment.

## 4. Auto-grow and push-down

An element whose content exceeds its declared height behaves according to
its `overflow` property:

| Overflow | Behaviour |
|----------|-----------|
| `grow` (default for text) | element height increases to fit content |
| `clip` | content is clipped, no height change, warning emitted |
| `ellipsis` | single line, trailing ellipsis when it does not fit |

Growth triggers push-down:

1. Children are ordered by `y`, then `x`, then document order. Ordering
   is computed by the loader and is stable.
2. When a child grows by `delta`, every later child whose top is at or
   below the growth's original bottom moves down by `delta`.
3. Band height is the maximum bottom edge of its children.
4. A band never shrinks below its declared minimum height.

This is the "can grow / push down" pair familiar from banded report
designers. It is the single most requested layout behaviour in invoice
work, and therefore it is specified before the schema.

Explicitly out of scope for 1.0: flow containers, columns inside a band,
text wrapping around images, and shrink-to-fit.

## 5. Text

- Wrapping is at word boundaries. A single word wider than the box is
  broken by character.
- Explicit `\n` is honoured and is not a wrapping opportunity.
- No hyphenation in 1.0.
- Trailing whitespace is ignored when measuring.
- Line height is `fontSize * lineSpacing`, default `lineSpacing = 1.2`,
  overridable per style.
- Vertical alignment inside a fixed box: top (default), middle, bottom.
- Text is measured through the adapter, never guessed. A layout that
  assumes `chars * averageWidth` is a bug.
- Runs of spaces and tabs between words collapse to one space at a
  wrapping opportunity. Other whitespace is preserved inside a word.
  This is the only text normalisation layout performs.
- Measurement uses fractional metrics and unrounded point values. Only
  render-document emission rounds to 0.01 pt.

Rich text (mixed styles inside one element) is not in 1.0. Multiple text
elements are the workaround, and the schema reserves a future `runs`
property.

## 6. Pagination

The algorithm is intentionally boring and must stay deterministic.

```text
emit ReportHeader (if any)
new page
loop:
  emit PageHeader
  while detail records remain:
      if this is the first record of a group:
          if GroupHeader + first Detail do not fit: new page, re-emit
              PageHeader and GroupHeader
          emit GroupHeader
      compute Detail height
      if Detail does not fit:
          close page (GroupFooter not yet emitted)
          new page
          emit PageHeader
          re-emit open group headers whose repeatHeader is true
          continue
      emit Detail
      if last record of group: emit GroupFooter
  emit ReportFooter
  emit PageFooter
  break
```

Rules that fall out of it:

- A page always has a PageHeader before content and a PageFooter after.
- A group header is never orphaned at the bottom of a page: it moves to
  the next page with at least one detail row. This is always true in 0.1;
  it is a layout rule, not a schema property.
- Page footers reserve their height for the whole page. Layout computes
  the content box as `page height - top margin - bottom margin -
  pageFooterHeight` when a footer exists. It does not discover the
  footer at the end.
- ReportFooter may start on a new page if it does not fit, per its
  `newPage` policy: `auto` (default), `always`, `never`.

## 7. Two-pass page numbering

`Page N of M` cannot be known in one pass. Therefore:

- Pass 1 runs the full algorithm with emission disabled, recording only
  geometry and page count. All auto-grow, push-down, and keep-together
  decisions are made identically.
- Pass 2 runs again and emits operations, substituting `M`.
- Page-number and page-count fields are the only fields whose value
  differs between passes. Any other two-pass-dependent field is a design
  smell and needs an ADR.

Cost: layout runs twice when `of M` is used. That is acceptable and
documented; reports without total-page fields run once.

## 8. Page breaks and keep-together

- `pageBreak: "after" | "before"` on a section forces a break.
- `keepTogether` on a band means the band is emitted on one page or moved
  whole; if it cannot fit on an empty page, it is emitted anyway with a
  warning. Silently splitting is never allowed.
- Detail rows are atomic. Row-level splitting is out of scope; a detail
  band that exceeds the content box is a layout error, reported, not
  truncated.

## 9. Repetition and totals

- Aggregates have an explicit scope: `detail`, `group`, `report`.
- Group aggregates reset when the group key changes.
- Running totals accumulate across the group scope they are declared in.
- Group keys are typed. `1` and `"1"` are different keys; null is its own
  key and groups together.
- The engine stable sorts by group key first (outermost group first), then
  by the declared `sort` fields, which order records inside the innermost
  group. Equal keys always retain source order; there is no
  `stable: false` option in 0.1.

## 10. Fidelity contract

Guaranteed across platforms:

- Page dimensions, margins, band positions, element bounds.
- Number of pages for a given measure adapter and font set.
- Element paint order.
- Text content, and line-break positions when the same font file is used.

Best effort:

- Exact glyph positions. Different rasterisers, hinting, and shaping
  produce sub-point differences.
- Line breaks when a platform substitutes a font.
- HTML flow mode, which is a different layout engine by definition.

Never promised:

- Pixel-identical output between PDF, HTML flow, DOCX, and XLSX.
- Identical output after a font file changes.

Tolerances and the test method are in [testing.md](testing.md).

## 11. Test invariants

Every layout fixture asserts:

1. Page count.
2. For each page: the ordered list of text runs with content, x, y,
   and width rounded to 0.01 pt.
3. Every image's resolved rectangle.
4. Every rule and rectangle's rectangle.
5. Absence of clipped or truncated content unless the fixture declares it.
6. Identical output when the same fixture is run twice.

Fixtures are the source of truth for the schema. If a fixture needs a
property the schema lacks, the schema changes — not the fixture.

## 12. Not in 1.0

- Multi-column bodies and newspaper flow.
- Floating elements, wrapping around objects.
- Subreports (reserved in the schema, not implemented).
- Charts and cross-tabs.
- Bidi, RTL, and complex script shaping.
- Interactive or drill-down HTML.
- Text justification with inter-word stretching.
