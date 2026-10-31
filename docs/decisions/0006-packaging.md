# ADR 0006 — One `.b4xlib`, optional jars

- Status: accepted
- Date: 2026-10-31

## Context

The original plan described seven separate module projects
(`B4XReportCore`, `B4XReportLayout`, `B4XReportPDF`, `B4XReportHTML`,
`B4XReportCSV`, `B4XReportXML`, `B4XReportJSON`) plus platform adapters,
and a rule that "a PDF-only application must not depend on spreadsheet
libraries".

That rule is about **jar dependencies**, not about B4X modules. Splitting
the B4X side into separate libraries creates a version-skew matrix (core
1.2 with layout 1.1 with pdf 1.0), multiple `.b4xlib` files to install, and
"which combination do I have?" support questions, for no runtime benefit:
unused B4X modules are inert and cost nothing in the jar.

B4X libraries are installed as `.b4xlib` files. Exporters that need a Java
library need that jar alongside; the library file itself cannot contain
jars.

## Decision

Ship **one** `.b4xlib` containing all public modules: core, template
parser, processing, layout, render model, and every exporter. Platform
adapters are small projects that may ship separately where they need
platform-specific jars.

Optionality is expressed through jars and through the exporter classes
the application chooses to call. `B4XReportPdf` requires PDFBox jars;
`B4XReportCsv` requires nothing. Adding the library never forces a format
dependency.

Build with `B4JBuilder.exe -Task=BuildLibrary`; the project lives under
`source/` and has a single version number.

## Consequences

- One version, one install step, one changelog. Support answers become
  possible.
- A PDF-only application still only adds PDFBox jars. The original
  requirement is met at the layer where it actually matters.
- Documentation must list jar requirements per exporter, since the
  `.b4xlib` itself will not say.
- The library is source-visible because `.b4xlib` files are zip archives
  of `.bas` files. This is acceptable under MIT and is recorded in
  ADR 0001.
- If one exporter ever needs a conflicting dependency, it moves to its own
  `.b4xlib` then — with an ADR, not pre-emptively.

## Alternatives considered

- **One `.b4xlib` per exporter.** Precise dependency expression, but
  version skew and an unusable install story for newcomers. Rejected.
- **Single Java jar, no B4X source.** Would protect nothing under MIT and
  would break the ability to share modules across B4A/B4J. Rejected.
- **Loose `.bas` modules, no library.** Forces every user to add files to
  their project and update them by hand; no versioning. Rejected.
