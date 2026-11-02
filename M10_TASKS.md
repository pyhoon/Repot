# M10: B4A HTML Print Path (PDF on Android)

## Milestone: M10 (2–3 weeks)
**Current stage:** M10 partial — B4A PDF print path implemented and verified on emulator-5554 (rasterised). Sync Export guard retained.

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

## Task 4: Wire into ReportPdfExporter — PARTIAL
- [x] Async path available via `ReportB4APrint.PrintHtmlToPdf` + `Wait For ReportB4APrint_PrintComplete`.
- [ ] Synchronous `Export` guard (`E-PDF-001`) retained: the print is async and cannot satisfy the sync `Boolean` contract or the sync test harness. Callers wanting a file use `ReportB4APrint` directly.

## Task 5: Tests
- [ ] B4A suite: async PDF test via `Wait For` (optional; sync harness doesn't fit async API). Manual verification done in `examples/B4A`.
- [x] `docs/compatibility.md` updated: B4A PDF → 1.0 (print path, verified, rasterised).

## Task 6: Docs — PARTIAL
- [x] `docs/b4x-notes.md`: Android print facts verified (PrintManager, createPrintDocumentAdapter, capturePicture, PrintedPdfDocument).
- [x] `docs/dependencies.md`: no new deps (platform APIs).
- [x] `docs/compatibility.md`: B4A PDF row → 1.0 (print path, verified).

## Task 7: Future enhancements (from B4X forum references)
- [ ] Vector PDF on B4A: replay render ops onto the Printing library's
  `PdfDocument` canvas (`Printing.jar`, already installed) instead of
  rasterising the WebView. Would give vector text and sync `Export`.
  References: Printing and Pdf creation (Erel), B4X PDF Generator (spsp).
- [ ] SaveAs support: let the user choose the output folder via the
  Storage Access Framework (SaveAs thread). Currently writes to the
  provided path (internal/external storage).
- [ ] B4X Open PDF: open the generated file in a viewer.

## Exit criteria
- [ ] B4A exports a non-empty PDF from invoice-basic on emulator-5554.
- [ ] `tools/ci.ps1 -RunEmulator` still exits 0 (B4A suite gains PDF checks, 0 errors).
- [ ] `docs/b4x-notes.md` records every Android API used.