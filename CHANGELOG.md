# Changelog

## 1.6.0 — M15 (release pending; suite blocked by font baselines)

Inline HTML preview for B4J desktop, and the facade accessor it needs.

### Added
- `Repot.GetHtml`: returns the exact HTML document `ExportHtml` writes
  (same render document, same `ReportHtmlExporter` pass), so a preview
  cannot drift from the exported file.
- `RepotViewer.b4xlib` (separate optional package,
  `tools/package-viewer-b4xlib.ps1`): `ReportHtmlViewer` as a B4X
  **custom view** — `DesignerCreateView` plus
  `#Event: PageFinished`, so it is added directly in the Layout Designer.
  One module serves both platforms (B4J `fx.WebView`, B4A core
  `WebView`); APIs verified against `jFX.xml` and `Core.xml`.
  Manifest: `Supported Platforms=B4A,B4J`.
- `preview/B4J/preview.b4j`: the reference use case — builds
  invoice-basic through the facade and shows `GetHtml` inline.
- `preview/B4A/RepotViewer.b4a`: compile-check project; the B4A branch is
  verified by a B4ABuilder run (exit 0).
- `TestHtmlPreview` in the engine suite: `GetHtml` is non-empty, contains
  the document markers, and is byte-identical to the `ExportHtml` file.

### Changed
- The viewer is deliberately **not** shipped in the core `.b4xlib`:
  the engine library builds as a headless (StandardJava) project, and a
  JavaFX-typed module fails that build. The viewer is a separate package,
  so server/console consumers never need JavaFX.
- `tools/ci.ps1`, `tools/run-fixtures.ps1` and `tools/package-b4xlib.ps1`
  resolve `B4JBuilder`/`B4ABuilder` from either installed root
  (`Program Files\B4X` or `Program Files\Anywhere Software`) instead of
  hardcoding one.

### Known limitations
- The B4J viewer is compile-verified but has not been run in a GUI on the
  build machine; `GetHtml` itself is covered by the suite. The B4A branch
  is compile-verified only (no emulator run in this milestone).
- `Destroy` on B4A removes the viewer by the index recorded at
  `Initialize`; removing other views from the same panel first would
  invalidate that index.
- The layout goldens for `invoice-basic` and `listing-multipage` fail on
  a machine whose font resolution differs from the one that generated
  them (goldens record `Arial`; this machine resolves `DejaVu Sans`,
  changing baselines). Unrelated to M15; needs a decision (see
  M15_TASKS.md).

## 1.5.0 — 2026-11-04

ODT and ODS export (M14). B4J 491 checks / 0 errors, B4A 346 checks /
0 errors on emulator-5554.

### Added
- `ReportOdtExporter`: OpenDocument text export — the dataset as one
  `table:table` (header row from the field definitions, one row per
  record) inside `office:text`, packaged as a valid ODF 1.2 document
  (`mimetype` first entry and uncompressed, `META-INF/manifest.xml`,
  `content.xml`). No third-party library; same own-minimal-writer
  approach as DOCX/XLSX.
- `ReportOdsExporter`: the same table model inside
  `office:spreadsheet`, with the spreadsheet media type.
- `Repot.ExportOdt` / `Repot.ExportOds` on the facade (DefaultDataSet,
  mirroring `ExportDocx`/`ExportXlsx`).
- B4J tests assert the ODF package structure directly through an
  inline-Java zip probe (first entry name/method, mimetype content,
  manifest root media type, content.xml well-formedness) plus content
  assertions on the extracted XML; B4A asserts export + existence like
  the DOCX/XLSX tests.
- CJK verification in the B4J PDF: the `multilang` fixture registers
  Noto Sans SC/KR subset fonts (fixture-only, OFL; generated with
  fontbox's `TTFSubsetter`, variable-font tables stripped — see
  `fixtures/_fonts/README.md` and `tools/font-subset/`) plus the Arabic
  and Hebrew pairs, and the suite asserts every script row — kana, han
  (Simplified and Traditional), hangul, Greek, Cyrillic, Arabic, Hebrew
  — extracts with zero `?`
  substitutions. CJK support requires the host to register a covering
  font; the mechanism itself is script-agnostic.

### Fixed
- ODS/ODT packages opened in Microsoft Excel reported "a problem with
  some content" (recoverable). Two package-shape changes address it:
  the manifest's root file-entry now carries `manifest:version="1.2"`
  (which ODF 1.2 consumers use to select the schema version), and the
  package now includes the spec-optional `styles.xml` and `meta.xml`
  parts that every real producer (LibreOffice, Excel) writes — the
  "LibreOffice-shaped package". The suite's zip probe asserts all of
  it, and the XML declarations drop the non-standard
  `standalone="yes"` to match known-good ODF writers. Verified in
  Excel LTSC 2508: the repair prompt is gone.

### Known limitations
- Cells are written as string cells, matching the XLSX writer's
  inline-string behaviour; typed numeric/date cells remain future work
  for both office spreadsheet writers.
- No ODF application was available on the development machine to open
  the output; verification is structural (zip layout + XML
  well-formedness), recorded in compatibility.md as a Tier-2 claim.

## 1.4.0 — 2026-11-04

Embedded font set and RTL base direction (M13). B4J 480 checks /
0 errors, B4A 342 checks / 0 errors on emulator-5554.

### Added
- `ReportPdfExporter.AddEmbeddedFont(Regular, Bold)`: register
  additional embedded font pairs beyond the primary `FontFile`/
  `FontFileBold`. `drawText` splits the shaped, visual-order string
  into maximal runs by font coverage and emits one text object per
  run, so a single export can mix Latin, Arabic and Hebrew. `?`
  appears only when no registered font covers a glyph. Mirrored on the
  `Repot` facade.
- `ReportPdfExporter.BaseDirection` ("ltr" default, "rtl"): bidi
  paragraph base direction for the PDF pass. With "rtl", pure-RTL lines
  keep trailing punctuation on the left edge and an LTR prefix anchors
  to the right edge (verified at content-stream level with
  `tools/pdf-probe`).
- Fixture `mixed-scripts`: Latin labels with Arabic and Hebrew values,
  digits inside both RTL scripts, and a three-script subtitle line —
  the case that was impossible in v1.3's single-font-pair exporter.
- B4A: the fixture exports through the vector canvas with introspected
  page counts (no engine changes; Android falls back across system
  fonts natively).

### Fixed
- Arabic shaping: a letter joined from the right took the medial form
  even when the following character was not a joiner (`دفع.` painted
  `ع` medial instead of final). The medial form now requires a joining
  next letter.

### Changed
- `tools/pdf-probe/DumpCodes` tracks `Tf` font switches and prints the
  active font per text object, so multi-font PDFs decode correctly.
- Documentation synced: compatibility (font set, base direction, mixed
  metric tolerance), b4x-notes (M13 verified facts: `hasGlyph(int)`
  takes a character code, not a codepoint; TextLayout mixed-script
  ratio 0.914; Bidi base-direction behaviour), testing counts.

### Known limitations
- Mixed-script line metrics: layout width (logical AWT fonts) and PDF
  width (embedded fonts) can differ by up to ~10% on mixed lines; the
  PDF's own alignment anchoring uses embedded widths and stays
  self-consistent.
- Base direction is exporter-level, not a template/style key.

## 1.3.0 — 2026-11-04

RTL text and complex scripts in the B4J PDF (M12). B4J 451 checks /
0 errors, B4A 337 checks / 0 errors on emulator-5554.

### Added
- Bidi run reordering in the B4J PDF (`ReportPdfExporter`): logical-order
  strings are chunked with `java.text.Bidi` and emitted in visual order;
  digits and other even-level runs inside an RTL span stay left-to-right.
  Base paragraph direction remains LTR (no RTL page-direction parameter).
- Arabic contextual shaping through the Unicode presentation forms
  (U+FE70–FEFF) with the mandatory lam-alef ligatures (U+FEF5–FEFC).
  The forms flow through the existing PDFBox embed/subset/ToUnicode
  path, so extracted text stays readable: PDFBox normalises the forms
  back to base letters and restores logical order on extraction.
- Right/center alignment now measures the processed (visual) string;
  visual width equals logical width, so anchors are unchanged.
- Embeddable fonts `fixtures/_fonts/NotoSansArabic-{Regular,Bold}.ttf`
  and `NotoSansHebrew-{Regular,Bold}.ttf` (SIL OFL 1.1, from
  googlefonts/noto-fonts), recorded in `docs/dependencies.md` §5.
- Fixtures `rtl-arabic` (Arabic-only: contextual forms, lam-alef,
  digits-in-RTL, Arabic-Indic digits) and `rtl-hebrew` (Hebrew-only,
  deliberately digits-free — Noto Sans Hebrew contains no digits or
  Latin). B4J tests assert logical extraction and no `?` substitution;
  visual-order emission is verified at content-stream level with the
  new `tools/pdf-probe` helpers (`DumpCodes.java`, `DumpPdf.java`).
- B4A: the two RTL fixtures export through the vector canvas with
  introspected page counts (no engine changes needed — Android shapes
  at draw time).

### Changed
- Documentation synced: compatibility fidelity tiers (Hebrew Tier 1,
  Arabic Tier 2 with documented limits), b4x-notes M12 verified facts
  (`Bidi.reorderVisually` is void and mutates in place; no byte-level
  `showText`; extraction normalisation), testing counts and fixture
  list, README capability statement.

### Known limitations
- Arabic shaping in the B4J PDF uses the presentation-form table, not a
  full GSUB engine: marginal letters and fonts whose shapes disagree
  with the Unicode forms may differ from HarfBuzz output by a glyph.
- A mixed Hebrew + digits line needs a font covering both (Noto Sans
  Hebrew has no digits); Arabic/Hebrew cannot share one embedded font
  in v1.3 (`FontFile` takes one file pair).

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
- HTML export in fixed-layout mode (M4).
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