# v1.6.0: Inline HTML Preview (M15)

**Current stage:** implementation complete on both platforms (compile-level);
release pending the layout-golden font decision. v1.5.0 remains the last
tagged release.

**Scope delivered:** `Repot.GetHtml` plus a separate optional
`RepotViewer.b4xlib` containing one viewer module with two native
backends — B4J `fx.WebView` and B4A core `WebView`. The core engine
library stays headless. No schema change; no new third-party dependency.

## Problem statement

`ReportHtmlExporter.ToHtml` produces a fixed-layout document. Every
release since v1.1 shipped without an embedded preview; the roadmap
(PLAN §7.4) and prior-art survey list a viewer, and the user confirmed it
is needed for B4J **and** B4A. What was missing is in-app viewing of the
HTML the engine already produces.

**Design choice (locked): HTML-only.** The viewer renders the same HTML
document `ExportHtml` writes; a second "PDF-layout" preview would
duplicate layout and drift, so it stays out of scope.

## Task 1: Verify the APIs — COMPLETE
- [x] `jFX.xml` (B4J 10.7): `WebView.Initialize(EventName)`, `LoadHtml`,
  `RemoveNodeFromParent`, `Pane.AddNode/Width/Height`.
- [x] `Core.xml` (B4A): `WebView.Initialize(EventName)`, `LoadHtml`,
  `Panel.AddView`, `Panel.RemoveViewAt`, `Panel.NumberOfViews`.
- [x] `B4JBuilder` in this version has no working `-Project` switch, so
  each example lives in its own folder.

## Task 2: `Repot.GetHtml` — COMPLETE
- [x] Returns `ReportHtmlExporter.ToHtml(Result.RenderDocument)`; same
  pass as `ExportHtml`, so preview and file are identical (tested).

## Task 3: Viewer module + separate package — COMPLETE
- [x] `preview/ReportHtmlViewer.bas` is a **B4X custom view**: `Type=Class`,
  `DesignerCreateView(Base, Lbl, Props)`, `Public mBase As B4XView`,
  `#Event: PageFinished`, plus a `CreateView(Parent)` path for code use.
  It appears in the Layout Designer's Custom Views list once
  `RepotViewer.b4xlib` is installed.
- [x] One module, `#If`-free: both platforms expose a `WebView` type, so
  `mWv As WebView` / `LoadHtml` / `IsInitialized` compile on B4J
  (fx.WebView) and B4A (android.webkit.WebView) alike.
- [x] **Boundary:** the module is *not* in the core library. The engine
  builds as `AppType=StandardJava` (headless); a JavaFX-typed module fails
  that build (`javafx.scene.layout` missing). New package
  `RepotViewer.b4xlib` via `tools/package-viewer-b4xlib.ps1` with
  `Supported Platforms=B4A,B4J`,
  `B4J.DependsOn=Json, JavaObject, jfx, jxui, Repot`,
  `B4A.DependsOn=Json, JavaObject, xui, Repot`.
- [x] Compile-check projects: `preview/B4J/preview.b4j` (JavaFX,
  exit 0) and `preview/B4A/RepotViewer.b4a` (B4ABuilder, exit 0).

## Task 4: Example — COMPLETE
- [x] `preview/B4J/preview.b4j`: builds invoice-basic through the
  facade, then `mViewer.LoadHtml(r.GetHtml)`.
- [ ] Not run in a GUI here (headless verification only).

## Task 5: Tests — COMPLETE (suite caveat)
- [x] `TestHtmlPreview` (+6 checks): non-empty, contains `INVOICE` /
  page-break CSS / `</html>`, byte-identical to the `ExportHtml` file.
- [x] Engine suite: **510 checks, 2 failures**.
- [ ] **Blocked:** `invoice-basic` and `listing-multipage` goldens record
  `font: Arial`; this machine resolves `DejaVu Sans`, changing baselines.
  Pre-existing, unrelated to M15. Decision: regenerate with a documented
  font baseline, or make measurement deterministic by bundling the font.

## Task 6: Docs, version, packaging
- [x] `compatibility.md`: inline-preview row for B4J **and** B4A at 1.6.
  `api-design.md`: `GetHtml`. `README.md`: platform row, layout (`ui/`,
  `B4J-preview/`), two-package install note, "What 1.6 delivers".
  `CHANGELOG.md`: 1.6.0 entry, release-pending caveat.
- [x] Version 1.6 (`ReportVersion.bas`, `#LibraryVersion: 1.6` both
  projects, core manifest `Version=1.6`, viewer manifest `Version=1.6`).
- [x] `dist/RepotViewer.b4xlib` packaged (1,244 bytes).
- [ ] `dist/Repot.b4xlib` not yet repackaged (decision pending).
- [ ] No tag/commit: the harness blocks writes inside `.git`; commit via
  GitHub Desktop.

## Acceptance — met at code/compile level, release gated

- [x] `GetHtml` returns the exact exported document (suite).
- [x] Core library still compiles headless (B4J exit 0).
- [x] B4J preview app compiles; B4A viewer branch compiles (exit 0).
- [ ] Full suite green: blocked by the two font-baseline goldens.
- [ ] Visual runs (B4J window, B4A emulator): pending manual checks.
