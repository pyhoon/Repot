# M9: Examples, Docs, Packaging, CI Hardening, Release

## Milestone: M9 (1–2 weeks)
**Current stage:** M9 COMPLETE — v1.0.0. Tag pending user action.

## Scope (from PLAN.md)
Ship a consumable library, a working example on each supported platform,
hardened build/CI scripts, and release artifacts. M8 runtime verification
is complete (B4J: 382 checks / 0 errors; B4A: 305 checks / 0 errors).

## Task 1: README and docs sync — COMPLETE
- [x] README status line: M8 complete, M9 in progress.
- [x] Removed stale "no exporter yet" note; exporters listed.
- [x] docs/compatibility.md: B4A DOCX/XLSX rows updated to verified.
- [x] docs/dependencies.md: jar requirements per exporter added.
- [x] docs/testing.md: CI shape references tools/ci.ps1.

## Task 2: Packaging (.b4xlib) — COMPLETE
- [x] tools/package-b4xlib.ps1: builds + packages 45 modules + jar/xml + manifest.
- [x] manifest.txt: Version=1.0.0, DependsOn rows.
- [x] Verified: demo/examples/B4J builds against installed Repot library (HTML+PDF produced).
- [x] Verified: demo/examples/B4A builds and runs against installed Repot .b4xlib on emulator-5554 ("Rendered 1 page(s)", HTML exported).
- [x] Output: dist/Repot.b4xlib.

## Task 3: Example application — COMPLETE
- [x] demo/examples/B4J: console example using installed Repot library; loads invoice fixture, exports HTML + PDF, verified (1 page, PDF produced).
- [x] demo/examples/B4A: example app bundling invoice fixture, exports HTML to internal storage, verified on emulator-5554 ("Rendered 1 page(s)", HTML path logged).

## Task 4: CI hardening — COMPLETE
- [x] tools/ci.ps1: B4J build + fixtures + B4A build + optional emulator run; exit 0 gate. Verified end-to-end (exit 0, including emulator run).
- [x] Documented in docs/testing.md.
- [x] run-fixtures.ps1 exit codes propagate.

## Task 5: Release prep — PARTIAL
- [x] Version bump 0.12 → 1.0.0 in ReportVersion.bas and project files.
- [x] CHANGELOG.md added.
- [ ] Tag v1.0.0 (user action).
- [x] Final verification: tools/ci.ps1 -RunEmulator exits 0.

## Exit criteria for M9
- [ ] `tools/ci.ps1` exits 0 on a clean machine with B4J + B4A installed.
- [ ] `Repot.b4xlib` installs and a consumer project builds against it.
- [ ] Example runs on B4J (and B4A where applicable).
- [ ] README and docs describe the shipped state accurately.
- [ ] Version tagged 1.0.0.