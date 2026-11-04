# v1.2.0: PDF introspection, SaveAs, and close-out

## Milestone: M11 (1–2 weeks)
**Current stage:** M11 complete — B4A PDF introspection (PdfRenderer page
count), facade bridges, and SAF SaveAs verified; B4J 411 checks / 0 errors,
B4A 327 checks / 0 errors on emulator-5554. RTL/complex-script shaping is
deferred to v1.3 (needs an Arabic-capable font under the dependency policy;
see Task 6).

## Scope
Complete the "optional follow-ons" from v1.1.0 as real, verified features:

1. B4A PDF page count via `android.graphics.pdf.PdfRenderer` (the v1.1.0
   module was a non-working scaffold; see Task 1).
2. Facade-level introspection so hosts ask the `Repot` object, not
   platform exporters (Task 2).
3. Full SaveAs via the Storage Access Framework, host-wired (Task 3).
4. Example, tests, docs synced (Tasks 4, 5, 7).

## Task 1: Rewrite `source/ReportPdfIntrospection.bas` — PDF page count on B4A — COMPLETE
- [x] Fix: v1.1.0 version compiled only because it was never registered in
  a project; its `#If Java` blocks held B4X code (invalid Java) and the
  `RandomAccessFile.GetField("mFd")` approach was invented.
- [x] Real implementation via `JavaObject` reflection only (verified
  against core.xml / JavaObject.xml):
  `ParcelFileDescriptor.open(File, MODE_READ_ONLY)` → `PdfRenderer`
  → `getPageCount`. No `#If Java`, no third-party jar. Fail-silent:
  missing/invalid file → 0.
- [x] `ExtractPdfText` documented as B4J-only: `PdfRenderer` has no text
  extraction API; B4A returns `""` without error.
- [x] Registered in `source/B4J/Repot.b4j`, `source/B4A/Repot.b4a`,
  `tests/B4J/tests.b4j`, `tests/B4A/tests.b4a` (52 / 52 / 52 / 53 modules).

## Task 2: Wire facade bridges in `source/Repot.bas` — COMPLETE
- [x] `GetPdfPageCount(Path) As Int` — B4A → `ReportPdfIntrospection`;
  B4J → `ReportPdfExporter.PageCount` (PDFBox static helper).
- [x] `ExtractPdfText(Path) As String` — B4J → PDFBox `extractText`;
  B4A → `""`.
- [x] Missing/unreadable file returns 0/`""` on both platforms:
  `ReportPdfExporter.PageCount/ExtractText` wrapped in `Try/Catch`
  (PDFBox throws its own exception on a missing file).

## Task 3: SaveAs via Storage Access Framework — COMPLETE
- [x] New module `source/ReportSaveAs.bas` with:
  - `CreateDocumentIntent(Mime, Title) As Object` — `ACTION_CREATE_DOCUMENT`
    (API 19+); returns an Intent on B4A, `Null` on B4J (B4J has no
    `Intent` type, so shared signatures are `As Object`).
  - `StartForResult(I As Object, Code As Int)` — reflection through
    `JavaObject.InitializeContext` → `Activity.startActivityForResult`
    (`StartActivityForResult` is NOT a B4A core keyword — proven by a
    build error); arms the request code. `ArmCode(Code)` for hosts that
    launch the intent themselves.
  - `HandleActivityResult(RequestCode, ResultCode, Data) As String` —
    `RESULT_OK == -1`, `Intent.GetData` → `content://` URI; "" otherwise.
  - `CopyFileToUri(SrcDir, SrcName, Uri) As Boolean` — ContentResolver
    `openOutputStream` via `Uri.parse`; `File.Copy2(File.OpenInput(...))`.
- [x] Facade `Repot.SaveAsPdfIntent(Mime, Title) As Object` replaces the
  fake `SaveAsPdf` scaffold; the host wires `Activity_Result` →
  `HandleActivityResult` → `CopyFileToUri`.
- [x] No permissions needed for ACTION_CREATE_DOCUMENT (SAF contract).

## Task 4: Example wiring (SaveAs end-to-end) — COMPLETE
- [x] `examples/B4A/example.b4a`: "Save As PDF" button →
  `Repot.SaveAsPdfIntent` → `ReportSaveAs.StartForResult` →
  `Activity_Result` → `HandleActivityResult` → `CopyFileToUri`.
- [x] Removed the duplicate `Activity_Create` and the invented
  `Data.Get("result")` handler + placeholder `CopyPdfToSaveAsUri`.
- [x] B4J: no SaveAs dialog needed; example keeps IDE save path.

## Task 5: Tests — COMPLETE
- [x] B4A suite: `TestPdfExport` gains introspection checks
  (`ReportPdfIntrospection.GetPdfPageCount` on the fixture PDFs:
  invoice = 1 page, listing ≥ 2 pages). 327 checks / 0 errors.
- [x] B4J suite: `TestFacade` gains `GetPdfPageCount`/`ExtractPdfText`
  bridging checks plus missing-file 0/"" contract checks.
  411 checks / 0 errors.

## Task 6: RTL and complex scripts (DEFERRED to v1.3)
- Bidi reordering for right-to-left runs in the B4J PDF (java.text.Bidi,
  visual-order emission) is feasible but needs an Arabic/Hebrew-capable
  embedded font. The bundled Noto Sans covers Latin/Greek/Cyrillic only;
  adding Noto Sans Arabic/Naskh requires a dependencies.md entry (OFL,
  same family) and a fixture update. Deferred, not silently dropped.
- B4A vector canvas uses Android system fonts; HarfBuzz shaping happens at
  draw time, so Arabic/Hebrew render correctly there today.

## Task 7: Docs — COMPLETE
- [x] `docs/compatibility.md`: introspection rows (B4A PageCount 1.2,
  ExtractText B4J-only) + SaveAs row.
- [x] `docs/api-design.md`: `GetPdfPageCount`/`ExtractPdfText`/
  `SaveAsPdfIntent` documented as implemented in v1.2.
- [x] `docs/b4x-notes.md`: M11 section — PdfRenderer restrictions (no text
  extraction, read-only open, API 16+), SAF CreateDocument facts,
  `StartActivityForResult` is not a core keyword, B4J has no `Intent`.
- [x] `docs/testing.md`: B4J 411 / B4A 327 counts and capability rows.

## Task 8: Version and packaging
- [x] Version 1.2.0 in `source/ReportVersion.bas` and the
  `tools/package-b4xlib.ps1` manifest (`Version=1.2`).
- [x] `tools/package-b4xlib.ps1` re-run after the version bump (dist
  274484 bytes); the `.b4xlib` includes `ReportPdfIntrospection` and
  `ReportSaveAs` and is installed to the B4A Libraries folder.
- [x] Final `tools/ci.ps1 -RunEmulator`: B4J 411 checks, B4A 327 checks,
  0 errors. Committed and tagged `v1.2.0`.

## Acceptance
- [x] `tools/ci.ps1` green: B4J library + fixture suite (411 checks,
  errors=0) + B4A library build.
- [x] `tools/ci.ps1 -RunEmulator` green: B4A suite 327 checks with the
  new introspection checks.
- [ ] `examples/B4A` demonstrates SaveAs through the SAF dialog on the
  emulator; the picked location receives the PDF bytes (manual check in
  the release notes).
