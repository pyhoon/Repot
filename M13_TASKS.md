# v1.4.0: embedded font set + RTL polish (M13)

**Current stage:** COMPLETE — v1.4.0 shipped. Scope: closed v1.3.0's
own known limitations — a single export can embed more than one font
(Arabic + Latin, Hebrew + digits), and the bidi base direction is
configurable. Small, self-contained milestone; no new dependencies.

## Problem statement

`ReportPdfExporter` embeds at most one font pair (`FontFile` /
`FontFileBold`) and `resolveFont` returns it for every text op. A mixed
line ("Customer: شركة الأفق") or a Hebrew row with amounts cannot be
drawn: uncovered codepoints degrade to `?`. The v1.3 fixtures worked
around this by being single-script. B4A has no such limit (system fonts
fall back natively).

Second gap: `bidiVisual` hardcodes `DIRECTION_LEFT_TO_RIGHT` as base
direction. A pure-RTL paragraph (Arabic sentence with no Latin) is
rendered correctly for its runs, but neutral punctuation and ordering
against the paragraph edge follow LTR rules.

## Task 1: Verify the toolset — COMPLETE (2026-11-04, JDK 19 + pdfbox 3.0.8)

- [x] Coverage probe verdict: **use `encode(String)`, not
  `hasGlyph(int)`**. `hasGlyph(int)`/`toUnicode(int)` interpret the int
  as a character code, not a Unicode codepoint — on Noto Sans Hebrew
  `hasGlyph(0x05D0)` returns false while `encode("א")` succeeds, and
  Noto Sans reports `hasGlyph(0x0627)=true` with no Arabic cmap
  (inverted results). `encode` throws exactly when the glyph is
  missing, which is the behaviour `safeText` already relies on in
  production. Probing is cheap: 1000 lookups in ~1 ms, so a per
  (font, codepoint) HashMap cache is plenty.
- [x] Mixed-script measurement: logical AWT fonts (`Dialog`,
  `SansSerif`) fall back across system fonts for Arabic inside a Latin
  string (no `.notdef` collapse). Advance of the probe line:
  logical 1105.9 vs sum of per-font physical (Noto) advances 1209.6 —
  ratio **0.914**. This is the documented Tier-2 metric risk: layout
  width comes from logical fonts, PDF width from the embedded fonts.
  PDF-side alignment stays self-consistent because `drawText` anchors
  on the embedded fonts' own `getStringWidth` (sum of run widths).
- [x] `Bidi(String, DIRECTION_RIGHT_TO_RIGHT)`: a pure-Arabic sentence
  becomes one level-1 run — the trailing period renders at the left
  edge (correct RTL paragraph behaviour). With LTR base the same
  sentence splits into levels (1, 0) and the period floats to the right
  end. Digits inside an RTL-base paragraph sit at level 2 (even) and
  stay LTR; `reorderVisually` handles the nesting.
- [x] Font-set API decision: exporter gains
  `AddEmbeddedFont(RegularPath As String, BoldPath As String)` building
  an ordered pair list; `FontFile`/`FontFileBold` remain the primary
  pair (registered first, backwards compatible). `loadFonts` is
  extended to load the whole set into a static ordered pair list, which
  `drawText` walks for run splitting (a single resolved font is no
  longer enough once runs may switch fonts mid-string). Per-pair bold
  selection as today: bold ops prefer the pair's bold font, falling
  back to its regular.

## Task 2: Font set API on the exporter — COMPLETE
- [x] `FontFile` / `FontFileBold` remain the primary pair (backwards
  compatible; existing fixtures unchanged).
- [x] `AddEmbeddedFont(RegularPath As String, BoldPath As String)` on
  `ReportPdfExporter` (and mirrored on the `Repot` facade, applied in
  `ExportPdf`); pairs stored in an ordered list, loaded by the new
  `addFontPair` Java static called once per pair after `loadFonts`.
  No schema keys, no new libraries.
- [x] Coverage-aware font choice: `pickFont` walks the pairs in
  registration order (bold ops prefer each pair's bold variant, falling
  back to its regular) with a per-(font, codepoint) `encode` cache;
  strings with no embedded fonts take the unchanged Standard 14 path.

## Task 3: Run-splitting drawText — COMPLETE
- [x] `drawText` (now also taking the op's bold flag) splits the shaped,
  visual-order string into maximal runs by font coverage and emits one
  `beginText/showText/endText` per run, advancing x by each run's
  measured width. Alignment width = sum of run widths.
- [x] `safeText` applies per run, so `?` appears only when NO
  registered font covers the glyph.
- [x] Single-font strings take the identical v1.3 code path (one run) —
  all pre-existing fixtures and goldens pass unchanged (verified: 451
  checks before the new fixture, 480 after).

## Task 4: RTL base direction — COMPLETE
- [x] `BaseDirection As String` on the exporter ("ltr" default, "rtl"
  accepted), fed to `bidiVisual` as `Bidi.DIRECTION_RIGHT_TO_LEFT`.
  Verified at content-stream level: with "rtl", the mixed subtitle
  paints digits first (leftmost) and the LTR prefix last (rightmost),
  and the Note row's trailing period paints at the left edge; with
  "ltr" the period floats to the right end. Extraction is
  direction-independent (PDFBox restores logical order), asserted
  in-suite.
- [x] No template schema change: exporter-level property, as planned.

## Task 5: Fixtures and tests — COMPLETE
- [x] `fixtures/mixed-scripts`: Latin labels + Arabic values, Hebrew
  with digits, the amount `1,250.50 ريال`, the lam-alef row (now with a
  trailing period to make base direction observable), and the
  three-script subtitle. B4J asserts: no `?`, Latin/Arabic/Hebrew
  extracted logically, digits and the decimal amount survive, single
  page; plus a second export with `BaseDirection = "rtl"`.
- [x] Shaping bug found and fixed during verification: a letter joined
  from the right took the *medial* form even when the next character
  was not a joiner (`دفع.` painted `ع` medial instead of final).
  `shapeArabic` now requires `arabicJoiner(next)` for the medial form.
- [x] `tools/pdf-probe/DumpCodes` tracks `Tf` font switches (multi-font
  PDFs decode through the active font; the probe prints it per Tj).
- [x] B4A: same fixture through the vector canvas + page count
  (emulator-5554).
- [x] Suite green on both platforms: **B4J 480 checks / 0 errors,
  B4A 342 checks / 0 errors**; counts recorded in testing.md.

## Task 6: Docs, version, release — COMPLETE
- [x] compatibility.md: font set, base direction, mixed-metric
  tolerance; the v1.3 "one font pair" limitation replaced.
- [x] b4x-notes: M13 verified facts section.
- [x] CHANGELOG 1.4.0; version bumps (`ReportVersion.bas`,
  `#LibraryVersion: 1.4` both platforms, manifest `Version=1.4`);
  `dist/Repot.b4xlib` repackaged and installed to
  `C:\B4X\Additional\B4A`; `tools/ci.ps1 -RunEmulator` green;
  commit; tag `v1.4.0`.

## Acceptance — MET

- One export contains Latin, Arabic and Hebrew text with no `?` and
  correct per-script glyphs, using three embedded font pairs
  (`mixed-scripts`, verified at content-stream level).
- Alignment anchors correctly for mixed runs (right/center measured on
  the sum of per-run embedded widths).
- `BaseDirection = "rtl"` produces correct paragraph-level ordering for
  a pure-RTL line with trailing punctuation (period at the left edge,
  LTR prefix at the right edge; probe-verified).
- B4A renders the same fixture (system fallback), page count verified.
- CI green: B4J 480 checks, B4A 342 checks, 0 errors.
