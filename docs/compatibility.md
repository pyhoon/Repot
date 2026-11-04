# Compatibility and Fidelity

Status: draft. This document states what each platform is expected to do
and what is explicitly best-effort. It is the contract behind the phrase
"works on B4A too".

## 1. Platform matrix

`0.1` = v0.1 target, `1.0` = v1.0 target, `1.2` = v1.2.0,
`--` = not planned for 1.0, `req` = available on request.

| Capability | B4J desktop | B4J server | B4A | Browser |
|------------|-------------|------------|-----|---------|
| Parse and validate `.repot` | 0.1 | 0.1 | 1.0 | -- |
| Data binding, expressions, grouping | 0.1 / 0.2 | 0.1 / 0.2 | 1.0 | -- |
| Layout and pagination | 0.1 | 0.1 | 1.0 | -- |
| PDF export | 0.1 | 0.1 | 1.0 (Printing library, vector canvas, sync, verified) | -- |
| HTML export (layout mode) | 0.1 | 0.1 | 1.0 | n/a |
| HTML export (flow mode) | -- (not implemented) | -- (not implemented) | -- (not implemented) | n/a |
| CSV / JSON export | 0.1 | 0.1 | 1.0 | -- |
| XML export | 0.2 | 0.2 | 1.0 | -- |
| DOCX export | 1.0 | 1.0 | 1.0 (verified) | -- |
| XLSX export | 1.x | 1.x | 1.0 (verified) | -- |
| ODT export | 1.5 | 1.5 | 1.5 | -- |
| ODS export | 1.5 | 1.5 | 1.5 | -- |
| Inline preview widget | 1.6 (`RepotViewer.b4xlib`: designer-addable custom view over fx.WebView; needs `jfx`,`jxui`) | -- (host renders HTML itself) | 1.6 (`RepotViewer.b4xlib`: same custom view over the core WebView; needs `xui`) | n/a |
| Native preview | host WebView (`ReportHtmlExporter.ToHtml`) | n/a | host WebView (`ToHtml`) | n/a |
| Print | opens the PDF in the system viewer | n/a | 1.0 (system print dialog, `ReportPrint`) | browser |
| PDF introspection (page count) | 1.0 (PDFBox) | n/a | 1.2 (`PdfRenderer`, `ReportPdfIntrospection`) | -- |
| Text extraction from PDF | 1.0 (PDFBox) | n/a | -- (Android `PdfRenderer` has no text API) | -- |
| SaveAs (user-chosen location) | -- | n/a | 1.2 (SAF `CreateDocument`, `ReportSaveAs`) | -- |
| B4i | -- | -- | -- | -- |

B4i is not claimed. Nothing in the design forbids it, but no support is
promised until it is built and tested.

## 2. Android strategy

Android cannot use the same PDF backend as the JVM:

- PDFBox and POI are too large and too JVM-dependent for a reliable B4A
  library.
- `android.graphics.pdf.PdfDocument` exists but requires a
  platform-specific drawing backend, not just a canvas swap.
- Android's HTML rendering and print pipeline are mature and already used
  by B4X libraries.

Therefore B4A renders the HTML output in an offscreen `WebView` and
prints it to PDF through `PrintDocumentAdapter`. Consequences that must be
documented publicly:

1. Layout is produced by the shared engine, but the final PDF is
   rasterised/printed by Android's WebView, not by our PDF canvas.
2. Font substitution may differ. Android's default sans/serif fonts are
   not DejaVu or Arial.
3. Page breaks are honoured because the HTML uses explicit page boxes,
   but sub-point positioning may differ.
4. Large reports may need a page-by-page render loop to stay inside memory
   limits.

If a future self-contained PDF writer is implemented against the canvas
interface, B4A can adopt it without changing layout. That is the reason
the canvas is abstract. See
[decisions/0004-b4a-output-strategy.md](decisions/0004-b4a-output-strategy.md).

## 3. Fonts

- Templates declare families with ordered fallbacks, never absolute file
  paths.
- The B4J adapter resolves fonts from a configured font set. For
  reproducibility and tests, fixtures use fonts with redistributable
  licences (candidates listed in
  [dependencies.md](dependencies.md)).
- PDF export embeds and subsets the resolved font. A font whose licence
  forbids embedding must be rejected with a diagnostic, not embedded.
- B4A uses Android system fonts by family name. Availability is documented
  per template: a template that requires a specific font must ship it or
  accept substitution.
- Text that depends on exact metrics is a documented risk, not a bug
  report.

### Multi-language text

- The template format, loader, binder and structured exporters
  (HTML/CSV/JSON/XML/DOCX/XLSX) are UTF-8 and preserve every script the
  host can supply. The `multilang` fixture covers Latin, Greek, Cyrillic,
  Japanese, Chinese, Arabic, Hebrew and Korean.
- B4A PDF uses Android system fonts, so those scripts render (subject to
  the device's installed fonts). The B4A suite exports the `multilang`
  fixture to PDF.
- B4J PDF uses the PDFBox Standard 14 fonts (WinAnsi) by default, so
  only Latin-1 text is guaranteed. Setting `ReportPdfExporter.FontFile`
  (and optionally `FontFileBold`) embeds a TrueType font and renders any
  script the font contains. The `multilang` test embeds Noto Sans
  (Latin/Greek/Cyrillic); the `rtl-arabic` test embeds Noto Sans Arabic
  and the `rtl-hebrew` test embeds Noto Sans Hebrew. Unsupported glyphs
  are replaced with `?` rather than failing.
- RTL text (v1.3): the B4J PDF draws logical-order text in visual order.
  Arabic runs are shaped contextual (initial/medial/final/isolated
  presentation forms, U+FE70–FEFF, plus the lam-alef ligatures
  U+FEF5–FEFC) and bidi runs are reordered with `java.text.Bidi`;
  digits inside an RTL span stay LTR. Extraction through PDFBox restores
  readable logical-order text (the stripper normalises presentation
  forms back to base letters), so copy/search works. The fixture fonts
  matter: Noto Sans Arabic has no Latin letters and Noto Sans Hebrew has
  no digits or Latin at all — see the font-set bullet below for how
  mixed lines are handled since v1.4.
- Embedded font set (v1.4): `ReportPdfExporter.AddEmbeddedFont` registers
  additional regular/bold pairs; `drawText` splits the processed string
  into maximal runs by font coverage and emits one text object per run,
  so one export can mix Latin, Arabic and Hebrew (the `mixed-scripts`
  fixture). `?` appears only when no registered font covers a glyph.
  `BaseDirection` ("ltr" default, "rtl") sets the bidi paragraph base
  direction: with "rtl", a pure-RTL line keeps trailing punctuation on
  the left edge and an LTR prefix anchors to the right edge.
- CJK scripts (v1.5): the run-splitting mechanism is script-agnostic —
  a codepoint renders whenever a registered font's cmap covers it, so
  Japanese, Chinese and Korean work in the B4J PDF as soon as a
  CJK-capable font is registered through `AddEmbeddedFont` (verified
  with Noto Sans SC + Noto Sans KR; note a single regional variant does
  not cover all three scripts — SC has no hangul, KR has the hangul).
  Simplified vs Traditional Chinese: the unified Han repertoire is in
  both — a full Noto Sans SC covers Traditional codepoints too, but
  shared codepoints draw with SC-preferred glyph shapes; register Noto
  Sans TC (also OFL) for Traditional-preferred shapes. TC does not
  cover some Simplified-only characters, so mixed reports register
  both. The `multilang` fixture now registers CJK subset fonts (see
  `fixtures/_fonts/README.md`) plus the Arabic and Hebrew pairs, and
  the suite asserts that every script row extracts from the PDF with
  zero `?` substitutions — including a Traditional Chinese row
  (繁體中文/學習，國字) drawn from the SC font's unified Han
  coverage. The subsets cover only the fixture's
  characters; full CJK deployments ship their own complete font.
  Caveat: the exporter loads single-file TTF/OTF fonts
  (`PDType0Font.load`); TrueType collections (`.ttc`) are not read.
- B4A PDF: no engine changes were needed for v1.3/v1.4. Android's system
  text stack shapes, reorders and falls back across fonts at draw time;
  the RTL and mixed-script fixtures export through the vector canvas
  with introspected page counts.
- ODT/ODS export (v1.5): minimal ODF 1.2 writers in the same style as
  the DOCX/XLSX ones — a zip package with `mimetype` (first entry,
  uncompressed, as ODF requires), `META-INF/manifest.xml` and
  `content.xml`, no third-party library. The dataset becomes one
  `table:table` (ODT: inside `office:text`; ODS: inside
  `office:spreadsheet`) with a header row from the field definitions.
  All cells are written as string cells, matching the XLSX writer's
  inline-string behaviour; typed numeric/date cells are a known
  limitation. The manifest's root file-entry carries
  `manifest:version="1.2"` and the package includes the spec-optional
  `styles.xml`/`meta.xml` parts (the "LibreOffice-shaped package") —
  both target Excel's ODF importer, which reported a repair prompt on
  the first release build (found in first release testing; fixed in
  v1.5.0 and verified in Excel LTSC 2508: the prompt is gone after
  adding the two parts). Verification is
  structural (zip layout + XML well-formedness asserted in the suite);
  no ODF application is installed on the development machine, so
  "opens in LibreOffice" is unverified — reported as a Tier-2
  equivalence claim, not Tier 1.

## 4. Fidelity tiers

**Tier 1 — identical and tested**

- Page size, orientation, margins.
- Band order and element paint order.
- Element bounds in points, after auto-grow and push-down.
- Page count for the fixture font set.
- Text content and page-number fields.
- Hebrew bidi reordering with an embedded font (v1.3, `rtl-hebrew`
  fixture): Hebrew needs no shaping, so embed + reorder + draw is exact.

**Tier 2 — equivalent, may differ in detail**

- Line-break positions when a platform substitutes a font.
- Glyph positions, kerning, and hinting.
- Image resampling quality.
- HTML flow mode relative to PDF.
- Arabic in the B4J PDF (v1.3, `rtl-arabic` fixture): correct bidi
  order and correct standard contextual forms via the presentation-form
  table, but it is not a full GSUB shaping engine — marginal letters
  with irregular joining behaviour, and fonts whose shapes disagree
  with the Unicode forms, may differ from HarfBuzz output by a glyph.
  B4A output for the same text is shaped by the OS and is the reference.

**Tier 3 — not promised**

- Byte-identical files across platforms or versions.
- Pixel-identical PDF vs. DOCX vs. XLSX.
- Identical layout after a font file is upgraded.
- Identical pagination between PDF and browser print preview.
- No RTL page/paragraph direction parameter: the paragraph base
  direction stays LTR; only RTL bidi runs are reordered.

Update v1.4: `BaseDirection` on `ReportPdfExporter` (and the `Repot`
facade) now selects the bidi base direction per export, which covers
the pure-RTL paragraph case above; a per-template/per-style direction
key still does not exist. Mixed-script line metrics remain Tier 2: the
logical-font measurement advance differs from the embedded-font draw
width by up to ~10% on mixed lines (recorded in b4x-notes), while the
PDF's own right/center anchoring uses the embedded widths and stays
self-consistent.

Every new exporter must state which tier it meets for each fixture.

## 5. Verification policy

A platform is claimed only when:

1. The code compiles with that B4X product on a supported version.
2. The fixture suite runs and its output is compared with the recorded
   tolerance.
3. An example application exists in `demo/`.
4. `docs/compatibility.md` says so.

Until all four are true, the platform is "in progress" in the README.
This rule exists because B4J libraries are routinely advertised as
cross-platform and then fail on Android's toolchain.

## 6. Version support

- B4J: the version used by the author's current toolchain, recorded in
  `docs/dependencies.md`. Older versions are not tested.
- B4A: same rule. The minimum Android API level is recorded when the
  adapter is implemented.
- Java: the version shipped with the B4X toolchain, recorded when the PDF
  adapter is added. No assumption about newer JDK features.
- Schema: the library declares which `.repot` schema versions it accepts.

## 7. What "supported" means

Supported means: it renders the fixtures within the stated tolerance on a
tested platform, and a defect in that path will be fixed. It does not
mean every feature of a competing product exists, nor that arbitrary
documents will render identically everywhere.
