# v1.3.0: RTL text and complex scripts in the B4J PDF

## Milestone: M12 (1–2 weeks)
**Current stage:** COMPLETE — v1.3.0 shipped. Scope: closed the one
feature explicitly deferred from v1.2.0. Bidi reordering and Arabic
shaping via presentation forms in the B4J PDF (embedded Noto Sans
Arabic/Hebrew). ODT/ODS and the browser viewer remain unscheduled
(on-demand items in PLAN §7.4).

## The honesty problem
Bidi is two separable problems and only one of them is solvable with the
MIT-only toolchain:

1. **Run reordering (solved everywhere).** "LTR paragraph containing an
   Arabic run" must emit *logical*-order text to PDF's `.showText` from
   the visual order. `java.text.Bidi` (JDK, headless, no new jar) does
   this. Hebrew is the clean test case: no contextual shaping, so
   reordering + an embedded font renders correctly.
2. **Arabic glyph shaping (best-effort, verified-first).** PDFBox draws
   Unicode codepoints; Arabic needs GSUB contextual forms (initial /
   medial / final / isolated) that only a shaping engine produces. The
   JDK does shape (HarfBuzz is inside the JDK's AWT text layout), but
   `TextLayout` hands back glyph *ids*, not Unicode — whether those can
   be drawn through PDFBox 3 (`PDType0Font.encodeGlyphId` or an
   equivalent API) must be verified against the actual jar before any
   code (repo rule). If it cannot, Arabic ships with bidi reordering and
   unshaped forms and is documented as Tier-3 fidelity, not silently
   claimed.

B4A already renders Arabic/Hebrew correctly: the system text stack
shapes at `Canvas.DrawText` draw time, so only right-alignment mapping
there needs a test.

## Task 1: Verify the shaping/reordering toolset — COMPLETE
Verified 2026-11-04 (JDK 19.0.2 headless, pdfbox-app-3.0.8):
- [x] `java.text.Bidi(String, DIRECTION_LEFT_TO_RIGHT)` headless: correct
  reachability and run boundaries. `Bidi.reorderVisually(levels, items)`
  is the safe way to order chunks (nested even levels handled by the
  JDK implementation); hand-rolled per-level reversal mangles neutral
  spaces — do not use it.
- [x] GID draw path *does* exist (`PDType0Font.encodeGlyphId(int)` and
  `addGlyphsToSubset`), but there is no byte-level `showText` — GID
  bytes can only be injected reflectively, and glyph-only content
  bypasses the ToUnicode CMap built by `encode()` (extraction breaks).
  **Chosen approach: presentation-form shaping instead** — mapped
  codepoints flow through the existing `showText`/`encode` path, so
  subsetting and ToUnicode keep working and text extraction remains
  possible.
- [x] The JDK shapes complex scripts (`TextLayout`, already used by
  `ReportB4JMeasure.MeasureWithFont`), so logical-order measurement of
  Arabic/Hebrew is already correct; only the PDF *draw* side lags.
- [x] Prototype shaping table validated against Noto Sans Arabic:
  0 missing presentation forms for U+0621–U+064A; contextual forms
  correct on spot checks (`فاتورة` → initial/final forms; `لا` → U+FEFB
  lam-alef ligature; letters after non-joining letters correctly
  isolated/final).

## Task 2: Fonts under the dependency policy — COMPLETE
- [x] Downloaded to `fixtures/_fonts/` from raw.githubusercontent.com
  (googlefonts/noto-fonts hinted builds): `NotoSansArabic-Regular.ttf`
  (240,456 B), `NotoSansArabic-Bold.ttf` (248,468 B),
  `NotoSansHebrew-Regular.ttf` (26,900 B), `NotoSansHebrew-Bold.ttf`
  (27,164 B).
- [x] Verified with AWT loading: family `Noto Sans Arabic` /
  `Noto Sans Hebrew`; Arabic covers 140/144 of U+FE70–FEFF (missing
  FE75/FEFD–FEFF are unused selector positions) and 594/668 of
  U+FB50–FDFC; lam-alef ligatures present (FEF5–FEFC). Hebrew does NOT
  appear in Noto Sans Arabic — separate font required (as intended).
- [x] `dependencies.md` §5 entries (licence OFL, source, size).
- [x] `_fonts` licence note file (`fixtures/_fonts/README.md`).

## Task 3: Bidi pass in the render pipeline — COMPLETE
Implementation decisions (differ from the original sketch in plan text):
- [x] All changes live in `source/ReportPdfExporter.bas` inline Java
  statics (B4J-gated); no schema keys, no B4A changes, no measurement
  changes: `MeasureWithFont` already measures through `TextLayout`
  (shaped); the PDF draw side was the only unshaped consumer.
- [x] Pipeline inside `drawText`: `shapeArabic(text)` (contextual forms
  + lam-alef across the full logical string) → `Bidi` runs over the
  *shaped* string → `reorderVisually` chunk order (void; mutates the
  array in place — the two-argument overload does not exist) → reverse
  codepoints of odd-level chunks only → existing `safeText` `?` fallback
  last (so unsupported presentation forms degrade to `?` exactly like
  any other unsupported glyph).
- [x] Alignment: right/center width measured on the processed string
  (visual width == logical width).
- [x] HTML/data exports keep logical order (browsers/apps handle bidi
  themselves) — draw-time pass only in the B4J PDF.

## Task 4: Fixtures and tests — COMPLETE
- [x] `fixtures/rtl-arabic`: Arabic-only (Noto Sans Arabic has no Latin
  letters — verified — so Latin labels would degrade to `?`; digits
  1042/2026/1,250.50 and Arabic-Indic ١٢٣٤٥ carry the digits-in-RTL
  case). B4J asserts logical Arabic extraction (`فاتورة`), digits
  surviving LTR, and no `?`.
- [x] `fixtures/rtl-hebrew`: Hebrew-only and deliberately digits-free
  (Noto Sans Hebrew has no digits/Latin at all — verified). Asserts the
  header word `פריט` extracts in logical order (PDFBox restores it).
- [x] One embedded font per exporter instance (`FontFile`) — Arabic and
  Hebrew cannot share Noto Sans Arabic (Hebrew coverage absent) — so
  separate exports per script. Same export may embed both via two
  files only if `loadFonts` is extended; not planned for v1.3.
- [x] B4A: both fixtures render through the vector canvas; export +
  `PdfRenderer` page count verified on emulator-5554.
- [x] Existing suite green (no regressions: Latin-only fixtures pass
  through the bidi pass unchanged). Final counts: B4J 451 checks /
  0 errors, B4A 337 checks / 0 errors.

## Task 5: Docs — COMPLETE
- [x] `docs/compatibility.md`: fidelity tiers updated (Hebrew Tier 1,
  Arabic Tier 2 with documented GSUB limits) and the multi-language
  section rewritten for v1.3.
- [x] `docs/b4x-notes.md`: new "JVM and PDF facts verified in M12"
  section (`Bidi.reorderVisually` void/in-place; no byte-level
  `showText`; stripper normalisation; font coverage surprises).
- [x] `docs/testing.md` counts (B4J 451 / B4A 337) and fixture tree;
  `README.md` non-goals bullet replaced by a "What 1.3 delivered"
  capability statement.
- [x] No template-format change: bidi works content-driven from
  `ReportPdfExporter`, no new schema keys.

## Task 6: Version, packaging, release — COMPLETE
- [x] Version 1.3.0 (`ReportVersion.bas`, manifest `Version=1.3`,
  `#LibraryVersion: 1.3` on both platforms).
- [x] `tools/ci.ps1 -RunEmulator` green (B4J 451 / B4A 337, 0 errors).
- [x] CHANGELOG entry; `dist/Repot.b4xlib` repackaged and installed to
  `C:\B4X\Additional\B4A`.

## Acceptance — MET
- Mixed LTR/RTL paragraphs render in correct visual order in the B4J
  PDF, with right-alignment anchored to the box edge (verified at
  content-stream level with `tools/pdf-probe`; extraction returns
  logical text).
- Hebrew: glyphs correct and ordering correct with an embedded Noto
  Hebrew font (`rtl-hebrew`, digits-free by necessity).
- Arabic: rendered per the Task 1 verdict — shaped via presentation
  forms (Tier 2, documented limits), never silently claimed.
- B4A output for the same fixtures verified on the emulator.
- CI green: B4J 451 checks, B4A 337 checks, 0 errors.
