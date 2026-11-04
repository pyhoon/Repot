# pdf-probe

Developer-only helpers (not part of the engine or the .b4xlib) for
verifying RTL glyph order in generated PDFs. Both read the first page.

## Why both tools exist

`DumpCodes.java` — paints of the PDF content stream: decodes every Tj/TJ
code through the page font's ToUnicode CMap in painting (left-to-right)
order. This is the only ground truth for what was drawn: for RTL text the
engine emits *visual* (reversed) order, and presentation forms for shaped
Arabic.

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
