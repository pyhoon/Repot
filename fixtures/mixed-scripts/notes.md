# mixed-scripts fixture

First multi-font export fixture (v1.4). One export embeds three font
pairs: Noto Sans (primary — Latin, digits, punctuation), Noto Sans
Arabic, Noto Sans Hebrew. `ReportPdfExporter.AddEmbeddedFont` registers
the fallback pairs; `drawText` splits the shaped, visual-order string
into maximal per-font runs and emits one text object per run.

## What it exercises

1. **Run splitting**: the subtitle line `Invoice فاتورة חשבונית 1042`
   contains all three scripts plus digits in one string — it must draw
   as four runs (Latin / Arabic / Hebrew / digits) with no `?`.
2. **Digits in Hebrew text** (`חשבונית 1042`, `שולם 2026-01`): Noto Sans
   Hebrew has no digits; the digits come from the Noto Sans fallback.
   This was impossible in v1.3 (single font pair).
3. **Arabic shaping + bidi** from v1.3 continues to apply per run
   (`لا يوجد دفع مستحق` lam-alef row).
4. **`BaseDirection = "rtl"`** (exporter property, set by the test):
   pure-RTL lines keep trailing punctuation on the left edge. Extraction
   is direction-independent (PDFBox restores logical order), so the
   in-suite assertion is export success + sane extraction; the visual
   punctuation placement is verified with `tools/pdf-probe` and
   documented in b4x-notes.

## Verified properties

- Measurement: logical AWT fonts fall back across system scripts; the
  advance differs from the embedded-font sum by ~9% on the probe line
  (Tier-2 metric risk, recorded in b4x-notes). Alignment anchors on the
  embedded fonts' own widths, so PDF output is self-consistent.
- Extraction: Latin extracts as Latin, Arabic/Hebrew as logical-order
  base letters, digits survive. No `?` anywhere.
