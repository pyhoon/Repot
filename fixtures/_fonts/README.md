Fonts in this folder

NotoSans-Regular.ttf / NotoSans-Bold.ttf
  Family: Noto Sans (Latin, Greek, Cyrillic)
  Licence: SIL Open Font License 1.1
  Source: https://github.com/googlefonts/noto-fonts (hinted/ttf/NotoSans)
  Used by: multilang fixture (embedded via ReportPdfExporter.FontFile)

NotoSansArabic-Regular.ttf / NotoSansArabic-Bold.ttf
  Family: Noto Sans Arabic
  Licence: SIL Open Font License 1.1
  Source: https://github.com/googlefonts/noto-fonts (hinted/ttf/NotoSansArabic)
  Used by: rtl-arabic fixture (embedded via ReportPdfExporter.FontFile)
  Notes: covers the Arabic base block U+0600-U+06FF and the Arabic
  presentation letter forms U+FB50-FDFC / U+FE70-FEFE (140/144 of the
  U+FE70 block; the gaps are unused variation-selector positions).

NotoSansHebrew-Regular.ttf / NotoSansHebrew-Bold.ttf
  Family: Noto Sans Hebrew
  Licence: SIL Open Font License 1.1
  Source: https://github.com/googlefonts/noto-fonts (hinted/ttf/NotoSansHebrew)
  Used by: rtl-hebrew fixture (embedded via ReportPdfExporter.FontFile)
  Notes: Hebrew needs no contextual shaping; only bidi run reordering.

All four families are redistributable under the SIL OFL 1.1 (font files
carry the licence; see https://openfontlicense.org). They are test
fixtures: a report that wants them embedded ships or references them
under the same licence. No proprietary font is ever committed here.
