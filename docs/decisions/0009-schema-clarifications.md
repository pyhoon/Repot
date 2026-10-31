# ADR 0009 — Fixture-driven schema clarifications

- Status: accepted
- Date: 2026-10-31

## Context

The draft `.repot` schema was written before any template rendered. Three
fixtures — an invoice, a multi-page listing, and a grouped statement —
then exercised it. They exposed ambiguities that would otherwise be
resolved differently by the loader, layout, and each exporter.

The full evidence and the fourteen clarifications are in
[schema-review.md](../schema-review.md). This ADR records the decision,
not the fixture detail.

## Decision

Adopt the review as written:

- `field.value` is an interpolated string; `text.text` is static.
- Exactly one `Detail` section in 0.1.
- Section array order is irrelevant; layout uses a fixed type order.
- Element `align`, `valign`, and `format` replace, not merge with, the
  style value.
- Aggregates are document-unique and referenced bare; dataset aggregates
  are report scope and group aggregates reset on the key.
- The engine sorts by group key first, then by the declared sort fields.
- `repeatHeader` is opt-in and defaults to `false`.
- A group header is never orphaned; it moves with at least one detail row.
- A line element's bounds are its endpoints, so a horizontal rule has
  `h = 0`.
- `date` is a valid parameter type.
- `{page.number}` and `{page.count}` are reserved layout fields.
- Image `fit` defaults to `contain`; `none` uses `dpi` when supplied.
- A grid may declare `columns` with `cellHeight` and no `rows`.
- Colours are `#rgb` or `#rrggbb`, with no alpha in 0.1.

The template format draft is updated to match. The schema version stays
`0.1` because this is a clarification of a draft, not a published major.

## Consequences

- Layout must implement key-first sorting. The statement fixture depends
  on it: it groups by `Month` and sorts by `Date`.
- No new element or section type is added. Detail variants, page-scope
  aggregates, and continuation descriptions are deferred until a fixture
  needs them.
- The loader and validator already enforce most of these rules. The
  remaining implementation work is layout and documentation.
- Any later change to these semantics requires a new ADR and, if the
  schema is already published, a version bump and migration.

## Alternatives considered

- **Leave sorting to the application.** Rejected: duplicate groups would
  depend on undocumented pre-sorting, and the fixture would be fragile.
- **Add a page-scope aggregate now.** Rejected: no fixture needs it, and
  scope syntax would complicate expression resolution.
- **Add a Detail variant for discounts.** Rejected for 0.1: a discount
  can be a line item, and a variant needs its own fixture and layout
  semantics.
- **Make `repeatHeader` default true.** Rejected: explicit is clearer,
  and the fixture already sets it; changing the default would be another
  behaviour change with no evidence behind it.
