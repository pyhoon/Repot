# Dependency Audit

Last reviewed: 2026-11-02.

Policy: no dependency enters the repository until it has an entry here.
Every entry records version, licence, platform support, size impact,
reason, and decision. No AGPL. No native binaries. No external processes.
LGPL is avoided in the core and permitted only for an optional exporter
that is clearly documented as such.

"Verify" means: not yet confirmed against the actual toolchain. Do not
write code that assumes it.

## 1. Build and toolchain

| Item | Version | Notes | Status |
|------|---------|-------|--------|
| B4J | 10.7 (`B4J.exe` 10.7.0.0) | Development target | verified locally |
| B4A | builder reports `B4ABuilder v14.20` | Android target, verified with SDK build-tools for android-36 | verified locally |
| `B4JBuilder.exe` | reports `B4JBuilder v10.70` | Headless build: `-Task=Build`, `-Task=BuildLibrary`, `-BaseFolder`, `-Project`, `-Configuration`, `-Output`, `-NoClean`, `-Obfuscate`; exit code 0 on success | verified locally |
| `B4ABuilder.exe` | reports `B4ABuilder v14.20` | Headless build: run with cwd = the project folder, `-task=Build -obfuscate=False`; `-Project` mis-parses as an error and must not be passed; builder auto-finds the single `.b4a` in BaseFolder; exit 0 on success | verified locally |
| Android SDK + emulator | android-36, emulator-5554 | Only needed to run the B4A suite; `adb` at `C:\android\sdk\platform-tools\adb.exe` on this machine | verified locally |

`-Task=BuildLibrary` requires `#LibraryName` in the project file. It writes
the library jar and XML metadata to the B4J Additional folder
(`%Additional%\B4J`), not to `Objects\` and not as a `.b4xlib`. Packaging
the published `.b4xlib` is a separate step (M9).

No CI service is required. A local or self-hosted Windows runner is
enough because B4JBuilder is Windows-only.

## 2. Core and layout

| Item | Licence | Platform | Decision |
|------|---------|----------|----------|
| B4X core collections (`List`, `Map`) | part of B4X | B4A/B4J | use |
| `Json` parser | part of B4X | B4A/B4J | use for template load/save |
| `Regex` | part of B4X | B4A/B4J | use for expressions and identifiers |
| `DateTime` / ticks | part of B4X | B4A/B4J | use for date formatting |
| `StringUtils` | part of B4X | B4A/B4J | evaluate; avoid if trivial to implement |
| `JavaObject` (B4X library) | part of B4X | B4A/B4J | use in `ReportB4JMeasure` (AWT on B4J, `android.graphics.Paint` on B4A) and the DOCX/XLSX zip helpers; required by consumers because it is not merged into the engine library jar |
| `java.desktop` / AWT fonts | JDK 19 | B4J, headless | use public `java.awt.font` APIs for measurement; no `sun.*` access, no `Graphics2D`, no UI thread |
| `android.graphics.Paint` / `Typeface` / `BitmapFactory` | platform API, no extra library | B4A | used by the measurement adapter and image decoding; no new dependency, platform tier versioned with the SDK |
| `Printing` (B4A library, `Printing.jar`) | B4A built-in | B4A | canvas-based `PdfDocument` for the B4A vector PDF exporter (M10); no new external dependency |
| `FileProvider` (B4A library, `FileProvider.b4xlib`) | B4A built-in | B4A | sharing generated files (e.g. PDF) with viewer apps via `FileProvider` + `Intent.ACTION_VIEW` |
| `XmlBuilder` | part of B4X | B4J / B4A | verify API and availability per platform |
| `Archiver` / zip support | part of B4X | verify per platform | needed for DOCX/XLSX/ODF; verify |

The core must remain pure B4X. Anything here that turns out to be
platform-specific gets an adapter, not a `#If` branch in logic code.

The B4J measurement adapter was verified headless on 2026-10-31 with
Java 19 (`-Djava.awt.headless=true`). It uses `java.awt.Font`,
`java.awt.font.FontRenderContext` and `java.awt.font.TextLayout` only.
`Graphics2D` and `sun.java2d` are not used: `JavaObject` cannot wrap the
`sun.*` return types, and the module system rightly refuses access.
AWT font sizes are integers, so the adapter measures at 1000 pt and
scales advances and vertical metrics linearly to the requested size.
This keeps fractional point sizes without rounding the template.

The shared `ReportB4JMeasure` module also carries the B4A branch
(verified 2026-11-02 on emulator-5554, API 36): `android.graphics.Paint`
measured at a base size of 1000 and scaled linearly, `Typeface` family
resolution with `sans-serif` substitution for unknown families, and
`Paint.FontMetrics` with ascent negated (Android reports ascent as
negative). See [b4x-notes.md](b4x-notes.md) for the verified B4A facts.

## 3. PDF

| Candidate | Licence | Android | Size | Decision |
|-----------|---------|---------|------|----------|
| Apache PDFBox 3.0.8 | Apache-2.0 | no | moderate (fontbox, commons-logging) | **primary for B4J**; all PDFBox code is `#If B4J`-gated so the B4A build never touches it |
| Apache PDFBox 2.0.x | Apache-2.0 | no | moderate | fallback if 3.x misbehaves |
| OpenPDF | LGPL-2.1 / MPL-2.0 dual | no | moderate | not adopted: B4J-only, and PDFBox 3 already embeds TrueType via `PDType0Font`; avoids LGPL overhead |
| PDFjet (jPDFjet / PDFjetB4A) | commercial; evaluation watermarked; OS edition feature-limited | B4A wrapper exists | moderate | **rejected**: paid/proprietary licence conflicts with MIT-only policy |
| Printing library (`PdfDocument`) | B4A built-in | yes | none | **adopted for B4A** vector PDF (M10) |
| iText 5 / 7 | AGPL-3.0 or commercial | no | small | **rejected**, licence incompatible |
| Apache FOP | Apache-2.0 | no | large | rejected: XSL-FO pipeline, not a canvas |
| openhtmltopdf / Flying Saucer | LGPL | no | large | rejected: HTML-to-PDF is a second layout engine |
| Headless Chromium | various | no | huge, external process | rejected: process, deployment, licence surface |
| PdfBox-Android | Apache-2.0 | yes | large | not planned; B4A uses the Printing library vector canvas |
| `android.graphics.pdf.PdfDocument` | platform API | yes | none | **adopted**: B4A vector PDF via the Printing library canvas (M10) |

The PDF backend sits behind the canvas interface in
[architecture.md](architecture.md), so this table can change without
touching layout.

iText is called out explicitly because the Crystal Reports Java runtime
used by a popular B4X wrapper requires iText 5.5. Anyone reusing that
runtime or its jars inherits AGPL obligations. Do not copy from it.

## 4. Office formats

| Candidate | Licence | Android | Decision |
|-----------|---------|---------|----------|
| Own minimal OOXML writer (zip + XML) | n/a | yes | **preferred for DOCX/XLSX**; needs validation against Word and LibreOffice |
| Apache POI | Apache-2.0 | poor | rejected for the engine; too heavy, Android-hostile |
| docx4j | Apache-2.0 | no | rejected: JAXB and size |
| ODF Toolkit (Apache) | Apache-2.0 | no | not now; ODT/ODS are on request |
| LibreOffice CLI | MPL-2.0 | no | rejected: external process |

The minimal writer is more work than calling POI, but it is small,
platform-neutral, and removes the largest dependency risk in the project.
It is validated by opening output in Word, LibreOffice, and a parser
(POI or python-docx/openpyxl in a test script, used only as a verifier,
not shipped).

Verifier tools are never linked into the library.

## 5. Fonts

| Candidate | Licence | Redistribution | Embedding | Notes |
|-----------|---------|----------------|-----------|-------|
| DejaVu Sans / Sans Mono | Bitstream Vera derivative, permissive | yes | verify | default candidate for fixtures and demos |
| Liberation Sans | SIL OFL 1.1 | yes | verify | metric-compatible with Arial |
| Noto Sans | SIL OFL 1.1 | yes | yes (TTF) | bundled in `fixtures/_fonts` (Regular/Bold, ~570 KB each) for the B4J embedded-font PDF test; Latin/Greek/Cyrillic coverage. CJK/Arabic/Hebrew need separate Noto builds, supplied by the host |
| Arial / Calibri | proprietary | no | no | referenced by name only, never shipped |

Fixtures use redistributable fonts only, so tests are reproducible and
the repository stays clean. Templates may name proprietary fonts; export
then depends on the machine having them, which is documented as a
fidelity risk rather than silently substituted.

Embedding permissions must be read from the font's OS/2 `fsType` field at
export time. Fonts that forbid embedding are rejected with a diagnostic.

## 6. Development-only

| Tool | Purpose | Notes |
|------|---------|-------|
| Python + python-docx / openpyxl | independent verification of generated office files | test-time only |
| `qpdf` or `pdfinfo` | PDF structural validation | test-time only, optional |
| Git, GitHub Actions or local runner | CI | no runtime dependency |

## 7. Rejected classes of dependency

- Anything AGPL.
- Anything requiring a native library or an external executable at
  render time.
- Anything that opens a database, network connection, or browser.
- Anything that evaluates JavaScript or another scripting language.
- Anything that would have to be bundled solely for Android and then
  forked for B4J.

## 9. Jar requirements per exporter

The `.b4xlib` itself carries no jars. Consumers add only what their
chosen exporters need:

| Exporter | Extra jars required |
|----------|---------------------|
| PDF (`ReportPdfExporter`) | Apache PDFBox 3.0.8 + fontbox + commons-logging (B4J only; B4A uses the HTML print path) |
| DOCX, XLSX, HTML, CSV, JSON, XML | none |

This keeps a PDF-only application from depending on spreadsheet
libraries, and vice versa, at the jar layer (see ADR 0006).

1. Propose the dependency in an issue, naming version and licence.
2. Add the row here with size, platform support, and reason.
3. Verify that it builds with the installed B4J version and, if relevant,
   B4A.
4. Only then add it to `source/`.

Removing a dependency is always acceptable without discussion.
