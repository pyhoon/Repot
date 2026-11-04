# rtl-arabic fixture

Arabic-only invoice, first RTL fixture (v1.3). Every drawn string is
Arabic text, ASCII/Arabic digits, or basic punctuation, because the
embedded font is Noto Sans Arabic and it contains **no Latin letters**
(verified: `ABCZabcz` cannot display; digits, `.`, `,`, `-`, `:`, `;`,
space do). Latin content in this fixture would degrade to `?` through
the existing unsupported-glyph fallback — that behaviour is unchanged
and intentional. Latin labels would require a second font per exporter
instance, which is v1.3-out-of-scope (`loadFonts` takes one file pair).

## What it exercises

1. **Contextual shaping** through the presentation-forms table in
   `ReportPdfExporter.shapeArabic`: initial/medial/final/isolated forms
   chosen by joining context across the full logical string.
2. **Lam-alef mandatory ligature**: `لا يوجد دفع مستحق` begins with
   `لام + ألف` → U+FEFB (isolated) as drawn text.
3. **Bidi reordering** through `bidiVisual`: Arabic runs (odd bidi
   level) are emitted in visual order; ASCII digits `1042`, `2026`,
   `1,250.50` sit in deeper even levels and stay LTR inside the RTL
   span.
4. **Arabic-Indic digits** U+0660-U+0669 (`١٢٣٤٥`), covered by the
   font's base-Arabic cmap.
5. **Hebrew is a separate fixture** (`rtl-hebrew`): Noto Sans Arabic
   contains no Hebrew glyphs.

## Verified properties

- `java.awt.Font.createFont` loads the TTF; family `Noto Sans Arabic`.
- Font coverage: 140/144 of U+FE70-FEFF; lam-alef FEF5-FEFC all
  present; 594/668 of U+FB50-FDFC.
- Extraction note: extracted text is presentation-form codepoints in
  visual (reversed) order, not logical-order base letters. Tests assert
  on presentation forms and on the absence of `?` substitution, not on
  the logical string.
