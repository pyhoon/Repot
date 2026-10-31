# ADR 0008 — Render document is a versioned display list

- Status: accepted
- Date: 2026-10-31

## Context

Every visual exporter needs the result of layout. Three shapes were
possible:

1. **Callbacks into exporter-specific drawing code** while layout runs.
   This is how many small report writers work. It is cheap for one
   exporter and disastrous for several: each format re-implements
   pagination decisions, and two-page numbering needs two independent
   runs per format.
2. **A semantic page model** that keeps sections, elements, styles, and
   expressions, leaving each exporter to interpret them. That moves
   layout into every exporter and makes PDF, HTML, and DOCX diverge.
3. **A flat display list** of resolved operations. Layout runs once;
   exporters are dumb translators.

The third option costs an explicit contract now, but it is the only one
that supports "build once, export many" and meaningful golden tests.

## Decision

Layout emits a versioned render document: pages containing an ordered
list of flat drawing operations (`text`, `image`, `line`, `rect`, `clip`,
`restore`, `link`) and named anchors, all in points. Text is emitted one
operation per laid-out line. Geometry is rounded half-up to 0.01 pt at
emission. The document does not refer to the template, dataset, styles,
or expressions.

The contract is specified in [render-document.md](../render-document.md).
Version 1 is frozen before M2 layout work. A breaking change requires a
new ADR, a version bump, and regenerated goldens.

Images carry an opaque in-process handle plus intrinsic size and a
normalised resource path. The handle is never serialised. In-process
build-and-export is the supported path; a serialised document is a test
artefact, not an interchange format.

## Consequences

- Exporters cannot invent their own layout. This is intentional.
- Text-line granularity means exporters do not need to wrap text, but a
  future flow-mode HTML exporter also consumes lines for fixed layout.
- Golden tests compare operation geometry and text content, not pixels.
- Two-pass page numbering reruns layout but emits operations only in the
  second pass; the render document itself does not need a placeholder
  value.
- Adding vector paths, gradients, or rich text later requires a contract
  change, not a quiet extension.
- A document cannot be reloaded and re-exported with images, because the
  handle is process-local. Fixing that would add a resource-loading
  contract, not a new handle type.

## Alternatives considered

- **Exporter callbacks during layout.** Rejected: couples pagination to
  each format and defeats build once, export many.
- **Keep the semantic model and let exporters lay out.** Rejected: three
  layout implementations, three sets of bugs, and no page-count
  agreement.
- **PDF content stream as the contract.** Rejected: ties HTML and DOCX
  to PDF concepts and makes goldens format-specific.
- **Pixel images per page.** Rejected: loses text, cannot be edited or
  searched, and makes DOCX output dishonest.
