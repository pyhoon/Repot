# Changelog

## 1.2.0 — 2026-11-04

B4A PDF verification and saving (M11). B4J 411 checks / 0 errors,
B4A 327 checks / 0 errors on emulator-5554.

### Added
- `ReportPdfIntrospection.GetPdfPageCount` (B4A): real page count of an
  exported PDF through `PdfRenderer` reflection — the v1.1.0 scaffold
  was replaced. Fail-silent: unreadable or missing file returns 0.
- Facade bridges: `Repot.GetPdfPageCount(Path)` (PDFBox on B4J,
  `PdfRenderer` on B4A) and `Repot.ExtractPdfText(Path)` (B4J only;
  Android's `PdfRenderer` has no text API, so B4A returns `""`).
- `ReportSaveAs` module: full Storage Access Framework SaveAs —
  `CreateDocumentIntent` (ACTION_CREATE_DOCUMENT), `StartForResult`
  (reflection to `Activity.startActivityForResult`),
  `HandleActivityResult` (returns the picked `content://` URI), and
  `CopyFileToUri` (`ContentResolver.openOutputStream`). No permissions
  required.
- `Repot.SaveAsPdfIntent(Mime, Title)` facade method.
- B4A example: "Save As PDF" button wiring the full SAF flow.

### Changed
- PDF introspection on B4A is covered by the test suite (fixture PDFs
  re-counted through `PdfRenderer`).
- Documentation synced: compatibility matrix, api-design (v1.2
  methods), b4x-notes (M11 verified facts), testing counts.

### Known limitations
- Text extraction from PDF stays B4J-only (see `ExtractPdfText`).
- Right-to-left text and complex-script shaping in the B4J PDF are
  deferred to v1.3 (needs an Arabic-capable embedded font).

## 1.1.0 — 2026-11-02

B4A vector PDF (M10), print, and the `Repot` facade.

### Added
- B4A vector PDF export through the `Printing` library `PdfDocument`
  (synchronous, verified): fonts, alignment, clipping, images,
  density-correct text. Replaces the v1.0 HTML-print route as the B4A
  PDF path.
- `ReportPrint` module and `Repot.PrintPdf/PrintHtml`: B4A opens the
  system print dialog; B4J opens the exported PDF in the system viewer.
- Optional PDF opening in examples (`java.awt.Desktop` on B4J,
  FileProvider on B4A).
- `Repot` facade: `LoadTemplate`, `SetDataSource(Single)`, `SetParameter`,
  `Build As ReportResult`, one-line `Export*` methods — the two-phase
  (build once, export many) workflow.
- B4J PDF: optional TrueType font embedding (`FontFile`/`FontFileBold`),
  right/center text alignment honoured, grouped-totals fixture.
- B4A print trigger in the example; B4J `-print` argument.
- B4J server example (`examples/server`): HTTP endpoint rendering a
  fixture to PDF.

### Fixed
- B4A vector PDF coordinate transform (top-left origin, no Y-flip);
  text size scaled by device density; alignment anchor behaviour;
  OpenPDF promoted to library helper modules (`ReportB4AOpen`,
  `ReportB4JOpen`).
- B4J `OpenPdf` uses `java.awt.Desktop` (no JavaFX dependency).

### Known limitations
- `ReportPdfIntrospection` shipped as a non-working scaffold (fixed in
  1.2.0); SaveAs existed only as a scaffold until 1.2.0.

## 1.0.0 — 2026-11-02

First release. B4J full feature set; B4A engine suite verified
(305 checks, 0 errors) with PDF export deferred to the HTML print path.

### Added
- Template model, `.repot` loader/writer, validation, dataset and
  parameter binding (M1).
- Banded layout engine with grid snapping, push-down, grouping,
  aggregates, expressions (M2, M6).
- Pagination with render-document emission and two-pass page numbering
  (M3).
- PDF export via Apache PDFBox 3.0.8 (B4J) (M3).
- HTML export in layout and flow modes (M4).
- CSV, JSON, XML data exporters (M5).
- DOCX and XLSX exporters via a minimal OOXML writer (M7).
- B4A adapter: shared modules with `#If B4A` branches, measurement via
  `android.graphics.Paint`, HTML/CSV/JSON/XML/DOCX/XLSX on both platforms
  (M8).
- Example application, `.b4xlib` packaging, CI driver (M9).

### Known limitations
- PDF export is B4J-only; B4A uses the HTML print path.
- Layout goldens are recorded against the B4J/AWT font set; B4A font
  substitution may shift line breaks (Tier 2 fidelity).
- DOCX/XLSX B4A support verified by the engine suite; visual fidelity
  on mobile is not promised.