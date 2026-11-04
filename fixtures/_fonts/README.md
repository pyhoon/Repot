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

NotoSansSC-Subset-Regular.ttf
  Family: Noto Sans SC (subset)
  Licence: SIL Open Font License 1.1
  Source: Noto Sans SC variable font, https://github.com/google/fonts
  (ofl/notosanssc), subsetted to the multilang fixture's characters.
  Used by: multilang fixture (registered via ReportPdfExporter.AddEmbeddedFont)
  Notes: covers exactly the codepoints used by the multilang fixture
  (Japanese kana and kanji, Chinese han, the fullwidth comma, plus the
  Latin/Greek/Cyrillic the source font carries) - NOT a general CJK font.
  A report that needs full CJK coverage ships its own complete font.
  The variable-font tables (gvar, HVAR, avar, fvar, STAT) were stripped
  after subsetting, so this is a static regular-weight instance; it is
  registered for both the regular and bold slots.

NotoSansKR-Subset-Regular.ttf
  Family: Noto Sans KR (subset)
  Licence: SIL Open Font License 1.1
  Source: Noto Sans KR variable font, https://github.com/google/fonts
  (ofl/notosanskr), subsetted to the multilang fixture's characters.
  Used by: multilang fixture (registered via ReportPdfExporter.AddEmbeddedFont)
  Notes: covers the fixture's Korean hangul syllables (and the ASCII the
  source font carries). Same subset/strip treatment as the SC file; a
  subset is not a general-purpose font.

All six families are redistributable under the SIL OFL 1.1 (font files
carry the licence; see https://openfontlicense.org). They are test
fixtures: a report that wants them embedded ships or references them
under the same licence. No proprietary font is ever committed here.

Regenerating the subsets (JDK + pdfbox-app jar required, see
docs/dependencies.md for the jar location):

  javac -cp <pdfbox-app.jar> tools/font-subset/SubsetTool.java ^
       tools/font-subset/StripVF.java
  java -cp <pdfbox-app.jar>;tools/font-subset SubsetTool ^
       NotoSansSC-VF.ttf NotoSansSC-Subset-Regular.ttf ^
       fixtures/multilang/data.json fixtures/multilang/template.repot ^
       fixtures/multilang/params.json sc
  java -cp <pdfbox-app.jar>;tools/font-subset SubsetTool ^
       NotoSansKR-VF.ttf NotoSansKR-Subset-Regular.ttf ^
       fixtures/multilang/data.json fixtures/multilang/template.repot ^
       fixtures/multilang/params.json kr
  java -cp tools/font-subset StripVF NotoSansSC-Subset-Regular.ttf ^
       NotoSansSC-Subset-Regular.ttf
  java -cp tools/font-subset StripVF NotoSansKR-Subset-Regular.ttf ^
       NotoSansKR-Subset-Regular.ttf

The source variable fonts are not committed (10-18 MB each); download
them from the google/fonts repository when regenerating.

