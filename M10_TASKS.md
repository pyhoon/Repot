# M10: B4A HTML Print Path (PDF on Android)

## Milestone: M10 (2–3 weeks)
**Current stage:** M10 complete — B4A PDF via Printing library (vector, sync) verified; B4A suite 314 checks, 0 errors.

## Scope
Make B4A produce PDF from a rendered report. Per `docs/compatibility.md` §2
and `docs/decisions/0004-b4a-output-strategy.md`, B4A does not use PDFBox;
instead it renders the HTML export in an offscreen `WebView` and prints it
to PDF through `PrintDocumentAdapter`. Layout is produced by the shared
engine; only the final rasterisation/printing is Android's.

This replaces the `E-PDF-001` guard in `ReportPdfExporter` on B4A with a
real implementation, or (preferred) a dedicated B4A print module.

## Task 1: Verify Android print APIs via JavaObject — COMPLETE
- [x] `android.print.PrintManager` obtainable via `Context.getSystemService("print")` (verified, non-null).
- [x] `WebView.createPrintDocumentAdapter(String)` exists on API 36 (verified, non-null).
- [x] `PrintAttributes.Builder` is the nested class (verified).
- [ ] `PrintManager.print(...)` shows a system dialog (not suitable for a file-path API); use a custom PrintDocumentAdapter to capture to a file (Task 2/3).
- [x] Documented in `docs/b4x-notes.md`.

## Task 2: Design the B4A print module — COMPLETE
- [x] New module `source/ReportB4APrint.bas` (B4A-only, `#If B4A`-guarded Java).
- [x] Input: HTML string (caller renders via `ReportHtmlExporter` first).
- [x] Output: PDF file path on internal/external storage.
- [x] Page size: A4 via `PrintedPdfDocument` + `PrintAttributes.MediaSize.ISO_A4`.
- [x] WebView lifecycle handled (create, load, capture, destroy) on the main looper.

## Task 3: Implement — COMPLETE (verified on emulator-5554)
- [x] Load HTML into an offscreen WebView (visibility INVISIBLE).
- [x] Capture full content via `WebView.capturePicture()`.
- [x] Rasterise to a multi-page `PrintedPdfDocument` (A4, scaled to page width).
- [x] Write the PDF to the requested output path; returns success flag via `PrintComplete` event.
- [x] Verified: `examples/B4A` produced a 2825-byte PDF from invoice-basic (log: "PDF -> ... ok=true").

## Task 4: Wire into ReportPdfExporter — COMPLETE
- [x] `ReportPdfExporter.Export` on B4A now calls `ReportB4APrint.PrintVectorPdf` (sync, vector, Printing library) and returns its result.
- [x] `E-PDF-001` guard removed on B4A.
- [x] Async raster path (`PrintHtmlToPdf`) retained as an alternative.

## Task 5: Tests — COMPLETE
- [x] B4A suite: `TestPdfExport` un-skipped; checks file exists + non-empty (PageCount/ExtractText stay B4J-only).
- [x] B4A check count: 305 → 314 (9 new PDF checks), 0 errors.
- [x] Manual verification: `examples/B4A` produced a vector PDF (ok=true).

## Task 6: Docs — COMPLETE
- [x] `docs/b4x-notes.md`: Printing library facts verified.
- [x] `docs/dependencies.md`: Printing library entry added.
- [x] `docs/compatibility.md`: B4A PDF row → 1.0 (vector, sync, verified).

## Task 7: Open PDF for viewing — COMPLETE
- [x] B4A example: `OpenPDF(dir, name)` via FileProvider + Intent ACTION_VIEW.
- [x] B4J example: `fx.ShowExternalDocument(File.GetUri(...))`.
- [x] Reference: B4X Open PDF snippet (Lucas Siqueira).

## Task 8: Future enhancements (from B4X forum references)
- [ ] SaveAs support: let the user choose the output folder via the
  Storage Access Framework. Currently writes to the provided path.
- [ ] Promote `OpenPDF` to a library helper module (cross-platform).

## Exit criteria
- [ ] B4A exports a non-empty PDF from invoice-basic on emulator-5554.
- [ ] `tools/ci.ps1 -RunEmulator` still exits 0 (B4A suite gains PDF checks, 0 errors).
- [ ] `docs/b4x-notes.md` records every Android API used.