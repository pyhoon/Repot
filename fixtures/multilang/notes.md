# multilang

Purpose: prove that the engine preserves Unicode text through load,
binding, layout and export.

- One row per script: Latin (accented), Greek, Cyrillic, Japanese,
  Chinese, Arabic, Hebrew, Korean.
- Header subtitle mixes the same scripts in a single text element.
- The fixture is one page; multi-page geometry is covered by
  `listing-multipage`.
- PDF fidelity depends on the platform fonts: B4J PDFBox uses the
  Standard 14 fonts (WinAnsi, Latin-1 only), so non-Latin scripts are a
  documented limitation there. B4A uses Android system fonts, which
  cover these scripts. HTML, CSV, JSON, XML, DOCX and XLSX are UTF-8 and
  are the supported multi-language paths on both platforms.
