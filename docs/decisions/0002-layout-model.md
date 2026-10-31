# ADR 0002 — Banded sections with optional grid snapping

- Status: accepted
- Date: 2026-10-31

## Context

Three layout models were on the table:

1. **Absolute placement** of every element on the page, Crystal Reports
   style at the section level and free positioning inside it.
2. **Grid/table cells**, as in the PaulMeuris report-writer tutorial,
   where a cell range defines each element on an A4 grid.
3. **Flow layout**, as in HTML/CSS, where content decides page breaks.

B4X's own prior art is almost entirely grid-based, because snapping is
easy to implement and easy to explain. Flow layout produces the best web
output but cannot give deterministic pagination across platforms. Pure
absolute layout gives control but a poor designer and poor table export,
since DOCX/HTML/XLSX all want cells.

A fourth path — bands for repetition plus cells for placement — was not in
the original plan and is the one that satisfies the most constraints.

## Decision

Reports are composed of ordered **bands** (ReportHeader, PageHeader,
GroupHeader, Detail, GroupFooter, PageFooter, ReportFooter). Within a
band, an element is positioned either by absolute `bounds` in points or by
a `cell` reference on an optional page grid. Both are normalised to points
at load time; layout and exporters only ever see points.

Auto-grow and push-down are part of the model, not an add-on: growing
elements shift later elements down within the band, and the band height is
the maximum bottom edge.

PageHeader and PageFooter are fixed-height, because a growing header makes
page counts unstable and `Page N of M` undefined.

## Consequences

- The schema carries two positioning modes. Risk of inconsistency is
  contained by normalising early; if the designer ends up using only one,
  the other is removed in a later major schema version.
- Designers get snapping without a separate alignment engine.
- Table-oriented exporters (HTML layout mode, DOCX, XLSX) can emit real
  cells, which is the main reason to keep grid information at all.
- Pagination complexity lands in one place, which is where it belongs.
- A band that exceeds the content box is a reported error, never a silent
  split.

## Alternatives considered

- **Absolute only.** Simpler schema, worse editing experience, and no cell
  structure for editable exports. Rejected.
- **Grid only.** Cannot express a growing row, cannot express a report
  footer that keeps with totals, and turns pagination into a table
  overflow problem. Rejected.
- **Flow / HTML-first.** Best browser output, but deterministic page
  counts across PDF, WebView, and desktop print cannot be guaranteed.
  Rejected as the model; retained as an optional HTML output mode.
