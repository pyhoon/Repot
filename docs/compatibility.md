# Compatibility and Fidelity

Status: draft. This document states what each platform is expected to do
and what is explicitly best-effort. It is the contract behind the phrase
"works on B4A too".

## 1. Platform matrix

`0.1` = v0.1 target, `1.0` = v1.0 target, `--` = not planned for 1.0,
`req` = available on request.

| Capability | B4J desktop | B4J server | B4A | Browser |
|------------|-------------|------------|-----|---------|
| Parse and validate `.repot` | 0.1 | 0.1 | 1.0 | -- |
| Data binding, expressions, grouping | 0.1 / 0.2 | 0.1 / 0.2 | 1.0 | -- |
| Layout and pagination | 0.1 | 0.1 | 1.0 | -- |
| PDF export | 0.1 | 0.1 | 1.0 (Printing library, vector canvas, sync, verified) | -- |
| HTML export (layout mode) | 0.1 | 0.1 | 1.0 | n/a |
| HTML export (flow mode) | 0.2 | 0.2 | 1.0 | n/a |
| CSV / JSON export | 0.1 | 0.1 | 1.0 | -- |
| XML export | 0.2 | 0.2 | 1.0 | -- |
| DOCX export | 1.0 | 1.0 | 1.0 (verified) | -- |
| XLSX export | 1.x | 1.x | 1.0 (verified) | -- |
| Native preview | host WebView (`ReportHtmlExporter.ToHtml`) | n/a | host WebView (`ToHtml`) | n/a |
| Print | opens the PDF in the system viewer | n/a | 1.0 (system print dialog, `ReportPrint`) | browser |
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
  script the font contains; the `multilang` test embeds Noto Sans
  (Latin/Greek/Cyrillic). CJK and Arabic/Hebrew need a font with those
  glyphs; unsupported glyphs are replaced with `?` rather than failing.
- Bidi and complex-script shaping are not implemented; RTL text is
  rendered in logical order.

## 4. Fidelity tiers

**Tier 1 — identical and tested**

- Page size, orientation, margins.
- Band order and element paint order.
- Element bounds in points, after auto-grow and push-down.
- Page count for the fixture font set.
- Text content and page-number fields.

**Tier 2 — equivalent, may differ in detail**

- Line-break positions when a platform substitutes a font.
- Glyph positions, kerning, and hinting.
- Image resampling quality.
- HTML flow mode relative to PDF.

**Tier 3 — not promised**

- Byte-identical files across platforms or versions.
- Pixel-identical PDF vs. DOCX vs. XLSX.
- Identical layout after a font file is upgraded.
- Identical pagination between PDF and browser print preview.

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
