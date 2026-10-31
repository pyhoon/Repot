# ADR 0004 — B4A after B4J, using an HTML print path

- Status: accepted
- Date: 2026-10-31

## Context

B4A is the most attractive part of the promise ("reports on the phone")
and the most expensive to deliver. Constraints:

- PDFBox, POI, and friends are too large and too JVM-dependent to rely on
  inside an APK.
- Android has `android.graphics.pdf.PdfDocument`, but drawing from our
  render document would require its own canvas adapter, its own font
  handling, and produces PDFs whose text extraction behaviour must be
  verified. It is a second backend, not a swap.
- Android's WebView already renders HTML and prints to PDF through
  `PrintDocumentAdapter`. Several B4X libraries rely on this.
- Android fonts differ from desktop fonts, so pixel fidelity is
  impossible regardless of the backend.

## Decision

B4A support ships **after** the B4J engine is stable — v1.0, not v0.1 —
and uses the shared engine to produce the HTML layout-mode output, then
renders it in an offscreen `WebView` and prints to PDF through
`PrintDocumentAdapter`.

The shared core, template parser, processing layer, and layout engine are
written to be Android-compatible from day one (pure B4X, no JavaFX, no
`java.awt`). Only the adapters and the final PDF step differ.

DOCX and XLSX are not offered on Android.

## Consequences

- The Android PDF is produced by WebView printing, so fidelity is Tier 2:
  layout and page breaks honoured, glyph positions may differ, font
  substitution likely unless the template ships a font.
- Very large reports may need a page-at-a-time render loop to stay within
  memory limits; this is documented rather than hidden.
- No JVM PDF dependency ships in the APK, which keeps APK size sane.
- A future self-contained PDF writer implementing the canvas interface
  could replace the print path without touching layout.
- Until the adapter is built and tested on a device, the README must not
  claim B4A support. No "should work on Android" wording.

## Alternatives considered

- **B4A in v0.1.** Would double layout and testing cost before the engine
  is proven, and force every early design decision through Android's
  constraints. Rejected.
- **PDFBox-Android.** Apache-2.0 and functional, but large, a port with
  its own release cadence, and unnecessary given the print path. Not
  planned.
- **Direct `PdfDocument` drawing from the render document.** Keeps text
  as text only if the platform cooperates, and is a full second backend.
  Kept as a documented fallback if WebView printing proves unsuitable;
  text-extraction behaviour must be verified before adopting it.
- **Server-side generation only, no B4A.** Loses the main differentiator
  and the reason the project exists. Rejected.
