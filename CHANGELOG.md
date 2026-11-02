# Changelog

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