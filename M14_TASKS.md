# v1.5.0: ODT and ODS export (M14)

**Current stage:** COMPLETE — v1.5.0 shipped. Scope: complete the
office-formats family — OpenDocument text and spreadsheet exporters
alongside DOCX/XLSX, using the same own-minimal-writer approach (zip +
XML, no new dependencies). ODT/ODS were deferred from v1.0 as "on
request" (PLAN §7.4); this milestone ships them so the exporter set is
symmetric across office formats.

## Problem statement

The engine exports DOCX and XLSX through hand-written OOXML writers
(`ReportDocxExporter`, `ReportXlsxExporter`): a temp folder of XML parts
zipped by a small inline-Java `zipFolder` helper, no third-party
library. ODF documents are the same shape of problem — a zip package
with an XML manifest and content — so the same approach applies. Without
ODT/ODS, users whose workflow is LibreOffice-based must parse CSV or
accept DOCX.

## Task 1: Verify the toolset — COMPLETE (2026-11-04, JDK 19)

- [x] ODF package layout verified with a Java probe
  (`OdfProbe.java`, temp dir): `mimetype` written as the FIRST zip
  entry with `ZipEntry.STORED` + pre-set size/CRC reads back first and
  uncompressed; `META-INF/manifest.xml` (root `/` entry with the
  document media type + `content.xml`) and `content.xml` DOM-parse as
  well-formed; `table:table`/`table:table-row`/`table:table-cell` +
  `text:p` structure asserted.
- [x] `java.util.zip.ZipOutputStream` STORED entry works from plain
  inline Java (no B4X wrapper needed). The DOCX/XLSX `zipFolder` already
  proves the DEFLATE path and `java.util.zip` availability on B4A, and
  this code path is the same module pattern.
- [x] Minimal namespaces for the planned content: `office`, `text`,
  `table` with `office:version="1.2"`. No `style`/`fo` needed while
  cells are plain string paragraphs (no automatic styles emitted).
- [x] Not verifiable locally: no LibreOffice or Python on this machine,
  so "opens in a real ODF application" is recorded as a verification
  note in compatibility.md rather than claimed.
- [x] First release testing found Excel (LTSC 2508) reporting "a
  problem with some content" on the ODS: the manifest's root
  file-entry lacked `manifest:version="1.2"` (the one structural
  difference from a documented-working minimal ODS). Fixed in both
  exporters, asserted by the zip probe, `standalone="yes"` dropped
  from the XML declarations to match known-good writers.
- [x] CJK verification (post-release, same milestone): extraction
  showed the multilang PDF rendered Japanese/Chinese/Korean as `?` —
  the embedded Noto Sans pair has no CJK coverage. Verified the
  run-splitting mechanism handles CJK when a covering font is
  registered (Noto Sans SC → kana + han; a Korean font → hangul; SC
  has no hangul). Bundled fixture-only OFL subsets
  (`fixtures/_fonts/NotoSansSC-Subset-Regular.ttf`,
  `NotoSansKR-Subset-Regular.ttf`, ~220 KB each) generated with
  fontbox `TTFSubsetter` + a variable-table strip
  (`tools/font-subset/`); the multilang test now registers the CJK
  subsets plus the Arabic/Hebrew pairs and asserts every script row
  extracts with zero `?`. B4J 499 checks / 0 errors.

## Task 2: ReportOdtExporter — COMPLETE
- [x] Same class shape as `ReportDocxExporter`; diagnostics on missing
  dataset (E-DATA-010) and IO failure (E-IO-001).
- [x] content.xml: the dataset as one `table:table` named "Report" —
  header row from field definitions, one row per record, all values as
  string cells (parity with the XLSX writer's inline strings; typed
  cells recorded as a known limitation).
- [x] mimetype (`application/vnd.oasis.opendocument.text`) first and
  STORED via the new `zipOdf` inline-Java helper; manifest lists root +
  content.xml. Values through the same `XmlEscape` treatment as DOCX.

## Task 3: ReportOdsExporter — COMPLETE
- [x] Same shape; `application/vnd.oasis.opendocument.spreadsheet`;
  content.xml body is `office:spreadsheet` with the same table model.

## Task 4: Facade and packaging — COMPLETE
- [x] `Repot.ExportOdt(OutputPath)` / `Repot.ExportOds(OutputPath)` on
  the DefaultDataSet, mirroring ExportDocx/ExportXlsx.
- [x] Both classes registered in the B4J/B4A library projects and both
  test projects (which compile the engine modules from source); the
  `.b4xlib` carries them as shared modules. Jar table in
  dependencies.md stays "none" for ODT/ODS.

## Task 5: Tests — COMPLETE
- [x] B4J `TestOfficeExport` extended: ODT and ODS export from the same
  invoice-basic "Items" dataset; file exists; the ODF zip probe asserts
  mimetype-first/STORED, manifest root media type, content.xml
  well-formedness, and dumps content.xml for B4X-level assertions
  (`office:text` + `table:table` + `text:p` for ODT;
  `office:spreadsheet` + cells for ODS).
- [x] Test-side bug found and fixed during verification: the probe
  originally derived the dump filename from the package path
  (`test-items-content.txt`), which never matched the name the B4X
  layer read (`test-items-odt-content.txt`) — the content assertions
  silently skipped. The dump path is now an explicit parameter.
- [x] B4A: same two exports + file exists.
- [x] Suite green on both platforms: **B4J 491 checks / 0 errors,
  B4A 346 checks / 0 errors** (tools/ci.ps1 -RunEmulator green);
  counts recorded in testing.md.

## Task 6: Docs, version, release — COMPLETE
- [x] compatibility.md: ODT/ODS rows, writer description, string-cells
  limitation, structural-verification note (Tier-2 claim).
- [x] dependencies.md: own-ODF-writer row adopted, ODF Toolkit stays
  "not adopted", zip row marked verified, jar table updated.
- [x] README: banner v1.5.0 with counts, output-format rows, pipeline
  diagram, "What 1.5 delivered".
- [x] testing.md: counts and the ODT/ODS verification row.
- [x] CHANGELOG 1.5.0; version bumps (`ReportVersion.bas`,
  `#LibraryVersion: 1.5` both platforms, manifest `Version=1.5`);
  `dist/Repot.b4xlib` repackaged and installed to
  `C:\B4X\Additional\B4A`; commit; tag `v1.5.0`.

## Acceptance — MET

- `Repot.LoadTemplate` + bind + `ExportOdt`/`ExportOds` produce files
  whose zip layout conforms to ODF (mimetype first, STORED, manifest
  correct) and whose content.xml is well-formed with the expected
  table structure, on both platforms.
- No new dependencies; `tools/ci.ps1 -RunEmulator` green
  (B4J 491 / B4A 346 checks, 0 errors).
