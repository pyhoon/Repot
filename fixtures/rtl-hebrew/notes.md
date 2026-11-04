# rtl-hebrew fixture

Hebrew-only listing (v1.3). Hebrew is the clean bidi proof: no
contextual shaping exists in the script, so bidi run reordering + an
embedded font renders it correctly with no glyph-substitution path
involved.

- Embedded font: Noto Sans Hebrew (`ReportPdfExporter.FontFile`),
  family `Noto Sans Hebrew` verified via `java.awt.Font.createFont`.
- `bidiVisual` reorders Hebrew runs to visual order. Tests assert the
  page-header word "פריט" extracts in reversed (visual) order and does
  not extract in logical order.

**Deliberately digits-free.** Noto Sans Hebrew contains no digits and
no Latin at all (verified: `0-9`, `A-Za-z`, `.` `,` `:` are uncoded;
only `-` and space exist outside the alphabet). Any numeric content
would degrade to `?` through the existing unsupported-glyph fallback.
Mixed Hebrew + digits therefore requires a font that covers both, used
through a separate exporter/fontfile — a documented fidelity limitation
for v1.3. The Arabic fixture covers the digits-in-RTL case instead
(Noto Sans Arabic ships ASCII + Arabic-Indic digit coverage).

Not exercised: niqqud marks and the apostrophe forms; covered by the
cmap but out of scope for the v1.3 assertions.
