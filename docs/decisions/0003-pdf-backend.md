# ADR 0003 — PDF canvas interface with PDFBox backend

- Status: accepted
- Date: 2026-10-31

## Context

PDF is the primary output and the one users judge. Options, with licence
reality included:

- **iText 5/7** — AGPL or a paid licence. The B4X Crystal Reports
  wrapper depends on the Crystal Java runtime, which ships iText 5.5;
  reusing that path would inherit AGPL obligations. Unacceptable for an
  MIT project.
- **PDFBox** — Apache-2.0, embeds and subsets TrueType fonts, handles
  Unicode, images, and metadata. JVM-only, moderate size.
- **OpenPDF** — LGPL/MPL fork of iText 4. Workable, with LGPL caveats.
- **Apache FOP** — Apache-2.0 but an XSL-FO pipeline, i.e. a second
  layout engine to fight.
- **openhtmltopdf / Flying Saucer** — LGPL, and again HTML layout rather
  than our layout.
- **Headless Chromium** — an external process with no place in a library
  or an Android app.
- **Own PDF writer** — no dependency, works everywhere, MIT-clean; but
  TrueType subsetting and CID fonts are a project in themselves.

The layout engine must not be coupled to whichever of these wins.

## Decision

Define a narrow, append-only **PDF canvas** (page, text run, image, line,
rect, clip, link) as the only surface layout may draw on. Implement it
with **Apache PDFBox 3.x** for the JVM. Exporters, not layout, own the
canvas implementation.

iText is rejected outright. No HTML-to-PDF engine is used.

## Consequences

- PDF export is a B4J-only capability; B4A needs a different path
  (ADR 0004).
- Applications must include PDFBox jars to get PDF; applications that only
  need CSV do not.
- Font embedding and subsetting are PDFBox's job. We are responsible for
  validating the font's `fsType` embedding permission and rejecting
  fonts that forbid it.
- The canvas is primitive enough that a future pure-B4X writer could
  replace PDFBox without changing layout — the route to PDF on Android
  and to a zero-dependency build.
- Coordinate mapping, page boxes, and rounding become our tests, not the
  library's.

## Alternatives considered

- **OpenPDF as primary.** Acceptable fallback if PDFBox 3 causes trouble
  on the target JDK; kept in `docs/dependencies.md`. Rejected as first
  choice because of LGPL caveats and a smaller active ecosystem.
- **iText.** Rejected on licence.
- **Write our own PDF now.** Attractive for B4A and for zero
  dependencies, but TTF subsetting and CID font handling would delay the
  engine by weeks. Deferred, not rejected: the canvas interface exists so
  it can be added later.
- **HTML then print to PDF.** Moves layout into a browser, which destroys
  determinism and cross-platform page counts. Rejected for PDF, adopted
  for Android only, where the alternative is worse.
