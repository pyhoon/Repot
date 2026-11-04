# pdf-probe

Developer-only helpers (not part of the engine or the .b4xlib) for
verifying RTL glyph order in generated PDFs. Both read the first page.

## Why both tools exist

`DumpCodes.java` — paints of the PDF content stream: decodes every Tj/TJ
code through the **active font's** ToUnicode CMap in painting
(left-to-right) order, tracking `Tf` font switches so multi-font PDFs
(v1.4 font set) decode correctly; the active font name is printed per
text object. This is the only ground truth for what was drawn: for RTL
text the engine emits *visual* (reversed) order, presentation forms for
shaped Arabic, and one text object per embedded-font run.

`DumpPdf.java` — the extraction view (`PDFTextStripper`): restores logical
order for RTL spans and normalises Arabic presentation forms (U+FE70-FEFF)
back to base letters (U+06xx). This is what `ReportPdfExporter.ExtractText`
returns and what PDF search/copy sees.

## Build / run

```text
javac -cp "C:\B4X\Additional\B4J\pdfbox-app-3.0.8.jar" DumpCodes.java DumpPdf.java
java  -cp ".;C:\B4X\Additional\B4J\pdfbox-app-3.0.8.jar" DumpCodes  <path to pdf>
java  -cp ".;C:\B4X\Additional\B4J\pdfbox-app-3.0.8.jar" DumpPdf    <path to pdf>
```

## M12 verification record

- ` fixtures/rtl-hebrew` PDF: content stream title letters are in visual
  (reversed) order (`U+FE...` n/a; Hebrew base letters reversed); the
  stripper view returns logical order.
- `fixtures/rtl-arabic` PDF: content stream Arabic runs carry presentation
  forms (U+FE70-FEFF, lam-alef U+FEF5-FEFC) in visual order; digits are
  own even-level chunks drawn LTR; the stripper view returns logical base
  letters, so extracted text is readable/searchable.

## M13 verification record

- `fixtures/mixed-scripts` PDF (three embedded pairs): the subtitle
  `Invoice فاتورة חשبונית 1042` paints as four per-font runs —
  NotoSans `Invoice 1042 `, NotoSansHebrew `תינובשח`, NotoSans space,
  NotoSansArabic `ةروتاف` — the correct UAX#9 visual order for an LTR
  paragraph (trailing digits attach to the RTL block). The Note row's
  trailing period paints as its own NotoSans Tj at the right end.
- Same fixture with `BaseDirection=rtl`: the same line paints `1042`
  first (leftmost) and `Invoice` last (rightmost); the trailing period
  paints at the left edge. Extraction (DumpPdf) is identical in both —
  PDFBox restores logical order regardless of base direction.
