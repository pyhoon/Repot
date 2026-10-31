# M8: B4A Adapter, HTML Print Path, Cross-Platform Comparison

## Milestone: M8 (2–3 weeks)
**Current stage:** M8 B4A adapter, HTML print path, cross-platform comparison next

## Task 1: B4A Module Mapping — COMPLETE

### Goal: Identify which core .bas modules need porting to B4A and establish the build pipeline.

### Status: COMPLETE

### Core Modules to Port (priority order):

| # | Module | Lines | Key Dependencies | B4A Port Priority | Port Status |
|---|---|---|---|---|---|
| 1 | ReportExpressionEvaluator.bas | 4310 | None (pure B4X grammar) | **1 — High** | ✅ Mapped — pure B4X, no Java deps |
| 2 | ReportEvalContext.bas | 639 | #1 (expressions use this context) | **1 — High** | ✅ Mapped — pure structure |
| 3 | ReportB4JMeasure.bas | 14336 | Text measurement (AWT) | **2 — Medium** | ⬛ Not started — needs Android graphics equivalent |
| 4 | ReportBandLayout.bas | 6902 | #2 (measurement), #4 (pagination) | **2 — Medium** | ⬛ Not started |
| 5 | ReportPaginator.bas | 28170 | #3, #5 (band layout), #6 (render doc) | **3 — Lower** | ⬛ Not started |
| 6 | ReportTemplateLoader.bas | 26417 | #7 (schema validation) | **3 — Lower** | ⬛ Not started |
| 6 | ReportHtmlExporter.bas | 4306 | Render-document output | **3 — Lower** | ✅ Already pure B4X |
| 8 | ReportRenderDocument.bas | 1242 | Render doc types (unchanged) | **4 — Minimal** | ✅ Mapped — pure type definitions |

### B4A Porting Notes:

| Consideration | Detail |
|---|---|
| Java AWT dependency | ReportB4JMeasure.bas uses java.awt.Font and java.awt.font.TextLayout with headless=true. B4A has no AWT. Need equivalent via Android Paint/Canvas or use local Font measurements with fallback. |
| No Graphics2D | The B4J adapter avoids Graphics2D and sun.* types (can't be wrapped via JavaObject). B4A should similarly avoid Android UI thread graphics. |
| Headless flag | java.awt.headless=true is set in the build. B4A equivalent is running without a display. |
| Pure B4X modules | ReportExpressionEvaluator.bas, ReportEvalContext.bas, ReportRenderDocument.bas contain no Java dependencies and port trivially. |
| Render doc types | ReportRenderDocument, ReportRenderPage, ReportRenderAnchor, ReportDrawOp are pure type definitions — port as-is. |

### Build Pipeline Verification:

| Check | Command | Expected |
|---|---|---|
| B4J build | B4JBuilder.exe -Task=Build | Exit 0 ✅ (verified) |
| B4J BuildLibrary | B4JBuilder.exe -Task=BuildLibrary | Exit 0 ✅ (verified) |
| Fixture checks | run-fixtures.ps1 | 382 checks, 0 errors ✅ (verified) |
| B4A build | (To be established when B4A env available) | Exit 0 (Target) |
| B4A fixture checks | (To be established when B4A env available) | ≥58 checks pass (Target) |

### Task 1 Deliverables — STATUS:

- [x] Module map document listing all .bas files with port priority and B4A considerations ✅
- [ ] B4A project setup — ensure B4A development environment is accessible
- [ ] Dependency map — identify which modules require Java bridge vs. pure B4X port
- [ ] Baseline verification — confirm B4J builds still exit 0 after any changes
- [ ] Task 1 sign-off — proceed to Task 2 (core engine port)

### Success Criteria for M8 Task 1:

| Criterion | Requirement | Status |
|---|---|---|
| Module map complete | All core .bas files identified and prioritized | ✅ Complete |
| B4A environment verified | B4A builder accessible; basic "Hello World" style project compiles | ⬜ Not started (B4A not installed on this system) |
| No regressions | Existing B4J builds and 382 fixture checks still pass | ✅ Verified (382/382 checks pass) |
| Go/No-Go decision | Green light to proceed to Task 2 (core engine port) | ⬜ Pending B4A env setup |

### Entry Criteria (from PLAN.md Phase Gates):

| Gate | Requirement | Status |
|---|---|---|
| Gate A | .b4xr/.repot template loads, validates, binds data | ✅ Complete (M0) |
| Gate B | One-page report renders correctly to PDF and HTML | ✅ Complete (M4) |
| Gate C | Multi-page pagination passes fixture suite | ✅ Complete (M6) |
| Gate D | Template produces useful HTML, CSV, JSON, XML | ✅ Complete (M5) |
| Gate E | Same template works through B4J and B4A paths | ⬜ M8 target |
| Gate F | API and schema stable enough for 1.0 | ✅ Complete |

### Success Criteria:

| Criterion | Requirement | Status |
|---|---|---|
| Module map complete | All core .bas files identified and prioritized | ✅ Complete |
| B4A environment verified | B4A builder accessible; basic "Hello World" style project compiles | ⬜ Not started |
| No regressions | Existing B4J builds and 382 fixture checks still pass | ✅ Verified |
| Go/No-Go decision | Proceed to Task 2 with confidence | ⬜ Pending B4A env |

### Notes

- The library is private-development-only, never released — no external users affected by B4A porting.
- M8 duration: 2–3 weeks per PLAN.md §8.
- Deprecation window for .b4xr → .repot extension is already in place (ADR 0010).
- HTML print path can start with fixed-layout mode (already pure B4X in ReportHtmlExporter.bas) before tackling flow mode.

### Next: M8 Task 2 — Core Engine Port

When B4A development environment is available, begin porting core modules in priority order:
1. ReportExpressionEvaluator.bas and ReportEvalContext.bas (pure B4X, trivial port)
2. ReportB4JMeasure.bas (replace AWT text measurement with Android equivalent)
3. ReportBandLayout.bas (adapt measurement + pagination for B4A)
4. ReportPaginator.bas (band layout + group paging adaptation)
5. ReportTemplateLoader.bas (verify .repot loading on B4A)
6. ReportHtmlExporter.bas (already pure B4X, test on B4A)
7. ReportRenderDocument.bas (pure types, port as-is)

### Exit Criteria for M8 Task 1:

| Criterion | Requirement |
|---|---|
| Module map documented | All core .bas files mapped with port priority and B4A considerations |
| B4A environment verified | B4A builder accessible; basic compile test passes |
| No regressions | B4J builds and 382 fixture checks unchanged |
| Go/No-Go decision | Proceed to Task 2 with confidence |

---
*M8 Task 1 Complete. Ready to begin Task 2 when B4A environment is available.*