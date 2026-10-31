# Dependency Audit

Last reviewed: 2026-10-31.

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
| B4J | author's installed IDE version (record exact build) | Development target | required |
| B4A | author's installed IDE version (record exact build) | v1.1 target | required later |
| `B4JBuilder.exe` | ships with B4J | Headless build: `-Task=Build`, `-Task=BuildLibrary`, `-BaseFolder`, `-Project`, `-Configuration`, `-Output`, `-NoClean`, `-Obfuscate`; exit code 0 on success | verified by forum report; verify locally |
| `B4ABuilder.exe` | ships with B4A | Android build, needs SDK | verify |

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
| `XmlBuilder` | part of B4X | B4J / B4A | verify API and availability per platform |
| `Archiver` / zip support | part of B4X | verify per platform | needed for DOCX/XLSX/ODF; verify |

The core must remain pure B4X. Anything here that turns out to be
platform-specific gets an adapter, not a `#If` branch in logic code.

## 3. PDF

| Candidate | Licence | Android | Size | Decision |
|-----------|---------|---------|------|----------|
| Apache PDFBox 3.0.x | Apache-2.0 | no | moderate (fontbox, commons-logging) | **primary for B4J** |
| Apache PDFBox 2.0.x | Apache-2.0 | no | moderate | fallback if 3.x misbehaves |
| OpenPDF | LGPL-2.1 / MPL-2.0 dual | no | moderate | acceptable alternative; LGPL caveat applies |
| iText 5 / 7 | AGPL-3.0 or commercial | no | small | **rejected**, licence incompatible |
| Apache FOP | Apache-2.0 | no | large | rejected: XSL-FO pipeline, not a canvas |
| openhtmltopdf / Flying Saucer | LGPL | no | large | rejected: HTML-to-PDF is a second layout engine |
| Headless Chromium | various | no | huge, external process | rejected: process, deployment, licence surface |
| PdfBox-Android | Apache-2.0 | yes | large | not planned; v1.1 uses the HTML print path |
| `android.graphics.pdf.PdfDocument` | platform API | yes | none | evaluated for B4A drawing backend later |

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
| Noto Sans | SIL OFL 1.1 | yes | verify | wide coverage, large files |
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

## 8. Change process

1. Propose the dependency in an issue, naming version and licence.
2. Add the row here with size, platform support, and reason.
3. Verify that it builds with the installed B4J version and, if relevant,
   B4A.
4. Only then add it to `source/`.

Removing a dependency is always acceptable without discussion.
