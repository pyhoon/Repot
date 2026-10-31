# Fixture-driven Schema Review

Status: **signed off 2026-10-31.** M0 is closed and M2 layout is
authorised. The decision record is
[ADR 0009](decisions/0009-schema-clarifications.md). The schema remains
draft `0.1`; it is frozen only when the fixture suite renders through the
real engine.

The three fixtures are the source of truth. If a clarification below
conflicts with a fixture, the fixture wins and the document is corrected.

## 1. Evidence from the fixture set

| Fixture | Sections | Element types | Behaviour exercised |
|---------|----------|---------------|---------------------|
| `invoice-basic` | ReportHeader, PageHeader, Detail, ReportFooter, PageFooter | text, field, image, line | absolute bounds, image `contain`, interpolated fields, date and number formats, align override, report aggregate, page numbering |
| `listing-multipage` | ReportHeader, PageHeader, Detail, ReportFooter, PageFooter | text, field, line | grid cells plus absolute rule, multi-page repetition, page numbering, report aggregate |
| `statement-grouped` | ReportHeader, PageHeader, GroupHeader, Detail, GroupFooter, ReportFooter, PageFooter | text, field, line | grouping, group aggregates, repeated group header, date format, page numbering |

Properties actually used by at least one fixture:

- Top level: `schemaVersion`, `id`, `name`, `description`.
- Page: `size`, `orientation`, `margins`, `grid.columns`, `grid.cellHeight`.
- Fonts: `family` (ordered list), `size`.
- Styles: `font`, `size`, `bold`, `colour`, `align`, `valign`, `overflow`,
  `format`.
- Parameters: `name`, `type`, `required`.
- Datasets: `name`, `kind`, `fields`, `aggregates`.
- Groups: `id`, `dataSet`, `key`, `sort`, `repeatHeader`, `aggregates`.
- Sections: `type`, `id`, `height`, `dataSet`, `group`, `keepTogether`,
  `elements`.
- Elements: `type`, `id`, `bounds` or `cell`, `style`, `align`, `text` or
  `value`, `format`, `resource`, `fit`, `colour`, `width`.

Reserved but unused: `page.dpi`, `page.footerReserve`, `grid.rows`,
`grid.cellWidth`, style padding/border/fill/italic/underline/lineSpacing,
parameter defaults, section `pageBreak`/`visible`, element `valign`/
`visible`/`z`, line `dash`, rect `fill`/`radius`, image `dpi`. They stay in
the draft because removing a documented property is a breaking change and
several are needed by M2/M3. They are not evidence that the feature works.

## 2. Proposed clarifications

These do not add fields except where noted. Each is a contract the loader,
validator, layout, and docs must share.

1. **`field.value` is an interpolated string.** Literal text and zero or
   more `{...}` expressions may be mixed, as in `Items: {LineCount}` and
   `Page {page.number} of {page.count}`. `text.text` stays static;
   `text` must not contain expressions. The M1 validator already rejects
   `value` on `text` and missing `value` on `field`.
2. **Exactly one `Detail` section in 0.1.** The validator already enforces
   this (`E-VAL-071`). Multiple details, or detail variants for discounts,
   are deferred.
3. **Section array order is irrelevant.** Layout emits in this order:
   ReportHeader, PageHeader, group headers (outermost first), Detail,
   group footers (innermost first), ReportFooter, PageFooter. The fixture
   files deliberately show ReportFooter before PageFooter; a loader must
   not treat file order as paint order.
4. **Element `align`, `valign`, and `format` override the style.** The
   override replaces the style value; it does not merge. The fixtures use
   `align: "right"` on individual headers and a `format` on a field whose
   style has none.
5. **Aggregates are document-unique and referenced bare.** A dataset
   aggregate is report scope; a group aggregate resets when the group key
   changes. This is implemented in M1 (`E-VAL-050`) and used by
   `statement-grouped`.
6. **Grouping sorts by key before the declared sort.** The engine stable
   sorts by the outermost group key, then each nested key, then the
   `sort` fields, which order records inside a group. This is needed by
   `statement-grouped`: it groups by `Month` but sorts by `Date`. Relying
   on the application to pre-sort by key would make duplicate groups
   possible and syntax-dependent.
7. **`repeatHeader` is opt-in and defaults to `false`.** It re-emits that
   group's header after a page break inside the group. The layout document
   now checks this flag instead of repeating every open header. The
   statement fixture sets `true` explicitly.
8. **A group header is never orphaned.** A group header and at least one
   detail row must fit together (`keepGroupHeaderWithDetail`, always true
   in 0.1). This is a layout rule, not a schema property.
9. **A line element's bounds are its endpoints.** `[x, y, w, h]` draws
   from `(x, y)` to `(x + w, y + h)`. A horizontal rule has `h = 0`. This
   is now stated in the render-document contract so exporters agree.
10. **`date` is a valid parameter type.** The validator already accepts
    it and the statement dataset uses `date`; `template-format.md` lists
    only `datetime` for parameters. Add `date` to that list.
11. **Page numbers are not expressions in the general sense.**
    `{page.number}` and `{page.count}` are reserved and supplied by
    layout. They must not be declared as parameters, fields, or
    aggregates.
12. **Image `fit` defaults to `contain`.** `none` uses `dpi` when present,
    otherwise the intrinsic pixel size at 96 dpi. The fixture only uses
    the default.
13. **A grid may specify `columns` with `cellHeight`** without `rows`.
    The listing fixture does exactly this: 24 columns and 16 pt rows. Rows
    are implicit. If both explicit and count forms are present, explicit
    sizes win, as already documented.
14. **Colours are `#rgb` or `#rrggbb`, no alpha.** The render document
    normalises to `#rrggbb`; alpha waits for a schema version that needs
    it.

## 3. Open questions from the format draft

| Question | Recommendation |
|----------|----------------|
| Does the invoice need a Detail variant for discounts? | No for 0.1. Model a discount as its own line item, or add a detail variant in 0.2 with a real fixture. |
| Is `cell` positioning actually used? | Yes: `listing-multipage` uses it. Keep both `bounds` and `cell`; the designer may enforce one at a time. |
| Does any fixture need a page-scope aggregate? | No. Defer; report and group scope cover the current set. |
| Does the listing need the last description repeated on continuation pages? | No. Defer; `repeatHeader` covers group context, not a repeated detail line. |

## 4. Adapter and render-document contracts

The companion contracts are:

- [architecture.md](architecture.md) §4: measurement, fonts, images,
  resources, and the PDF canvas.
- [render-document.md](render-document.md): the versioned display list.
- [ADR 0008](decisions/0008-render-document.md): why the display list was
  chosen.

These are internal contracts. The public API exposes a platform adapter
object, not an abstract interface, because B4X has no stable portable
interface mechanism. That keeps the core pure B4X without inventing one.

## 5. Sign-off

Signed off by the project owner on 2026-10-31, with all clarifications and
recommendations accepted as written.

- [x] Clarifications 1–14 accepted.
- [x] Open questions answered as recommended.
- [x] ADR 0008 accepted.
- [x] Adapter signatures in `architecture.md` accepted.
- [x] M2 layout authorised.

M2 may add layout, pagination and exporter code. Any change to the
template schema after this point follows the ADR and versioning rules in
[template-format.md](template-format.md) §6.
