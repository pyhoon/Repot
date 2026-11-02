# multilang

Purpose: prove that the engine preserves Unicode text through load,
binding, layout and export.

- One row per script: Latin (accented), Greek, Cyrillic, Japanese,
  Chinese, Arabic, Hebrew, Korean.
- Header subtitle mixes the same scripts in a single text element.
- The fixture is one page; multi-page geometry is covered by
  `listing-multipage`.
- PDF fidelity depends on the platform fonts. B4A uses Android system
  fonts, which cover these scripts. B4J PDFBox can embed a TrueType font
  (`ReportPdfExporter.FontFile`) to render any script the font contains;
  the test embeds Noto Sans, which covers Latin/Greek/Cyrillic. CJK and
  Arabic/Hebrew need a font with those glyphs (e.g. Noto Sans CJK);
  missing glyphs are replaced with `?` rather than failing.
- HTML, CSV, JSON, XML, DOCX and XLSX are UTF-8 and are the supported
  multi-language paths on both platforms.
