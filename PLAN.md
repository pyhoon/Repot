# Repot — Development Plan and Coding-Agent Brief

**Document status:** Working plan, open-source route\
**Project:** Repot\
**Ecosystem:** B4X (B4J first, B4A second)\
**Template format:** Versioned JSON, `.b4xr` extension\
**License:** MIT, all components\
**Current stage:** M1 in progress (core model, loader, validation, binding)

---

## 1. Mission

Build the reporting engine that B4X developers keep re-implementing: a
portable template format plus a deterministic layout engine that produces
paginated PDF and HTML, editable office documents, and structured data
exports from the same report definition and the same application-supplied
data.

The reference workflow is a banded report — report header, page header,
group header, detail, group footer, page footer, report footer — with
grouping, aggregates, page numbering, and multi-page output.

## 2. Decisions already taken

These are settled unless an ADR explicitly supersedes them. Do not
re-litigate them during implementation.

| # | Decision | Record |
|---|----------|--------|
| 1 | Everything is MIT. No commercial edition, no license checks, no crippled core. | [ADR 0001](docs/decisions/0001-open-source-model.md) |
| 2 | Layout is banded sections whose elements may be grid-snapped rather than purely absolute. | [ADR 0002](docs/decisions/0002-layout-model.md) |
| 3 | PDF rendering goes through a narrow canvas interface, bound to PDFBox. iText is rejected on license grounds. | [ADR 0003](docs/decisions/0003-pdf-backend.md) |
| 4 | B4A ships after the B4J engine, using an HTML-to-print path. No JVM PDF library on Android. | [ADR 0004](docs/decisions/0004-b4a-output-strategy.md) |
| 5 | The `.b4xr` schema is frozen last, driven by fixtures. JRXML is not adopted. | [ADR 0005](docs/decisions/0005-template-format.md) |
| 6 | One `.b4xlib` ships all public modules; jar dependencies are the optional boundary. | [ADR 0006](docs/decisions/0006-packaging.md) |
| 7 | The project is named Repot; no `B4X` prefix in file or class names. | [ADR 0007](docs/decisions/0007-project-name.md) |

The open-source decision has one irreversible consequence: published MIT
code stays MIT. Therefore no feature may be reserved for a future paid
product. If money ever arrives, it comes from sponsorship, the designer,
or paid integration work — not from withholding engine capability.

## 3. Positioning

The competition is not Crystal Reports. It is:

- Java reporting libraries wrapped for B4J, whose failure mode is
  dependency and deployment friction.
- Hand-rolled report writers that stop at a grid and a Word table.
- PDF primitive libraries that leave layout entirely to the caller.

The differentiator is the unglamorous part: **pagination that survives
real data, with data supplied by the application rather than by SQL
hidden in the template.** Full analysis in
[docs/prior-art.md](docs/prior-art.md).

## 4. Architecture summary

Layer responsibilities, allowed dependencies, measurement units, error
model, and determinism rules are in
[docs/architecture.md](docs/architecture.md). In brief:

1. Template model — parse, validate, version, serialise.
2. Data layer — datasets, fields, parameters, typed values.
3. Processing — sort, group, expressions, aggregates, visibility.
4. Layout — measure, arrange, push down, paginate.
5. Render document — immutable pages of drawing operations.
6. Exporters — PDF, HTML, CSV, JSON, XML, DOCX, XLSX.
7. Platform adapters — measurement, fonts, images, printing, file access.

The core, layout, and processing code must be pure B4X with no JavaFX,
Android UI, DOM, or server types. Everything platform-specific enters
through an adapter.

The render document is a display list: pages containing text runs,
images, lines, rectangles, and clips in points. Every exporter consumes
it, which is what makes "build once, export many" possible.

## 5. Template format summary

UTF-8 JSON, `.b4xr`, explicit `schemaVersion`, stable element IDs,
unknown optional properties ignored, unknown required constructs
rejected with a diagnostic. Draft schema and an example template:
[docs/template-format.md](docs/template-format.md).

The schema is not frozen. It is validated against the fixture set first.

## 6. Data and expressions

- Data sources are registered by name by the host application. Initial
  providers: List of Maps, List of custom objects, single-record Map.
- The engine never owns a connection, never parses SQL, and never
  executes anything from a template.
- Parameters are typed and explicit.
- Expressions use a small, hand-written grammar: field and parameter
  references, literals, arithmetic, comparison, boolean operators,
  concatenation, parentheses, `If(cond, a, b)`, and a fixed function
  set. No scripting runtime, no `eval`, no dynamic compilation.
- Values preserve type: string, integer, floating point, decimal,
  boolean, date/time, null.
- Culture and time formatting come from an explicit locale object, never
  the ambient platform default.

Expression semantics are specified and unit-tested before grouping ships.

## 7. Scope by release

### 7.1 v0.1 — first useful release

- Load and validate `.b4xr`; save templates; programmatic construction.
- Page size, orientation, margins, points as the internal unit.
- ReportHeader, PageHeader, Detail, ReportFooter, PageFooter.
- Text, data-bound field, image, line, rectangle, page number, page count.
- Dataset registration from List/Map structures; parameters.
- Text measurement, wrapping, auto-grow, push-down.
- Multi-page pagination; two-pass page numbering.
- PDF export.
- HTML export in fixed-layout mode.
- CSV and JSON export.
- B4J desktop example; B4J server example.
- Fixtures: one-page invoice; multi-page listing.

### 7.2 v0.2 — grouping

- Group headers and footers, nested groups.
- Subtotals, grand totals, running totals.
- Conditional visibility and conditional formatting.
- Keep-together; page breaks; repeated group headers on page break.
- XML export.
- HTML "flow" mode for semantic output.

### 7.3 v1.0 — stable

- Expression coverage as documented.
- DOCX export with real paragraphs and tables.
- B4A adapter and example using the HTML print path.
- Documented fidelity tolerances per platform and format.
- Dependency inventory, release packaging, migration policy.
- Public API and schema stable enough to promise compatibility.

### 7.4 After 1.0, on evidence of demand

- XLSX export, then ODT/ODS if requested.
- Browser viewer component.
- Subreports, charts, cross-tabs.
- Drill-down or interactive HTML.
- Visual designer as a separate application consuming the public API.
- Template inheritance and reusable styles.
- RTL and complex script support.

## 8. Milestones

Estimates assume one developer, agent assistance, and 15–20 focused hours
per week. They are planning ranges, not commitments.

| Milestone | Scope | Estimate |
|-----------|-------|----------|
| M0 | Docs, ADRs, fixture definition, dependency audit, interface contracts | 1 week |
| M1 | Core model, JSON load/save, validation, datasets, parameters | 2 weeks |
| M2 | Layout: bands, grid snapping, measurement adapter, push-down, pagination | 3–4 weeks |
| M3 | PDF export, two-pass page numbering, layout goldens | 2–3 weeks |
| M4 | HTML export, fixed-layout mode, preview path | 1–2 weeks |
| M5 | CSV and JSON exporters | 1 week |
| M6 | Expressions, grouping, aggregates, conditional rules | 2–3 weeks |
| M7 | DOCX export | 2 weeks |
| M8 | B4A adapter, HTML print path, cross-platform comparison | 2–3 weeks |
| M9 | Examples, docs, packaging, CI hardening, release | 1–2 weeks |

Indicative: v0.1 at M0–M5 (about 10–13 weeks); v1.0 at M0–M9 (about
17–24 weeks). B4A depth is the largest source of variance.

### Phase gates

- **Gate A:** a `.b4xr` file loads, validates, and binds data.
- **Gate B:** a one-page report renders correctly to PDF and HTML.
- **Gate C:** multi-page pagination passes the fixture suite, including
  page counts and repeated headers.
- **Gate D:** the same template produces useful HTML, CSV, JSON, and XML.
- **Gate E:** the same template works through B4J and B4A paths within
  documented tolerances.
- **Gate F:** API and schema stable enough for 1.0.

A milestone is not complete because it compiles. Its acceptance tests and
examples must pass.

## 9. Testing and CI

Strategy, fixture layout, and the pixel-diff prohibition are in
[docs/testing.md](docs/testing.md). Summary:

- Unit tests for parsing, expressions, grouping, aggregates, and
  formatting.
- Layout fixtures compare **element geometry and text runs** as golden
  JSON, not rendered pixels.
- Export fixtures check PDF page counts and extracted text, HTML
  structure, CSV quoting, JSON round-trip, XML well-formedness, and
  office files opened by a real parser.
- Headless builds use `B4JBuilder.exe -Task=Build`, verified on 2026-10-31
  with B4J 10.7 and Java 19. It exits non-zero on failure and is suitable
  for a CI runner. Exact output behaviour is recorded in
  [b4x-notes.md](docs/b4x-notes.md).
- `source/RepotTests` lints the fixtures against the draft schema and
  is driven by `tools/run-fixtures.ps1`, which maps the result file to a
  process exit code. Layout goldens are added in M3.

## 10. Packaging and distribution

One `.b4xlib` for the engine and all exporters, plus the jars each
exporter needs. Rationale and consequences:
[ADR 0006](docs/decisions/0006-packaging.md).

Distribution is through the B4X forum, GitHub releases, and the
repository itself. No activation, no trial, no registration.

## 11. Governance

- License: MIT for code, documentation, fixtures, and examples.
- Contributions: DCO sign-off, inbound = outbound MIT. No CLA. The
  project will not adopt a more restrictive license later.
- Irreversible or expensive decisions are recorded as ADRs in
  `docs/decisions/`. An ADR is required before changing the template
  schema, the layout model, the render document contract, or the public
  API.
- The schema follows semantic versioning. Breaking changes require a
  major bump and a documented migration.
- Support is best-effort. See [CONTRIBUTING.md](CONTRIBUTING.md).

## 12. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Pagination becomes unmaintainable | Freeze the render document contract early; golden geometry fixtures per milestone |
| Text metrics differ between platforms | Adapter boundary; document tolerances; compare semantics, not pixels |
| Java dependencies fail on Android | Keep the core pure B4X; HTML print path for B4A; no JVM PDF lib there |
| Schema churn breaks users | Schema last; fixtures first; semver plus migration functions |
| Scope creep from office formats | DOCX only at 1.0; XLSX/ODF on demand |
| Single-maintainer burnout | Narrow 0.1 scope; best-effort support policy; no paid SLA |
| iText/AGPL contamination via transitive jars | Dependency inventory; audit before adding any jar |
| Font licensing | Explicit font policy; embed only redistributable fonts |
| Reports too large for memory | Provider and streaming extension points; page and memory limits |

## 13. Coding-agent operating instructions

1. Read `README.md`, this plan, and the relevant docs before changing
   code. Check `docs/decisions/` for constraints.
2. Work one milestone at a time. Do not implement the roadmap in a single
   pass.
3. Before each milestone, list the files to create or change and the
   acceptance tests to add.
4. Do not invent B4X APIs. Verify every library, class, and method against
   the target B4X version or record it as an unverified dependency.
5. Prefer B4X-native code and collections for shared logic.
6. Keep B4J and B4A specifics behind adapters.
7. Do not introduce JavaFX, Android UI, DOM, or server types into the
   core, layout, or processing layers.
8. Do not add a third-party dependency without an entry in
   `docs/dependencies.md` giving version, license, platform support, size,
   and reason.
9. No AGPL, no native binaries, no external processes in the engine.
10. Do not implement arbitrary code execution, SQL execution, or file
    access from templates.
11. Keep the public API small and documented. Propose API changes in an
    ADR before broad implementation.
12. Add tests and fixtures with each feature. Never defer testing to the
    end.
13. Do not build designer or viewer UI before the engine is stable.
14. Keep documentation synchronized with behaviour. Mark unimplemented
    features as planned.
15. Do not claim B4A support until the code has been compiled and tested
    with B4A.
16. Do not claim an exporter is complete until its files have been opened
    or parsed by an independent implementation.
17. When a requirement is ambiguous, write an ADR recording the decision
    and trade-off instead of silently choosing.

### Required output at the end of each milestone

- Source files created or changed, with a one-line purpose each.
- Tests and fixtures added, and the result of running them.
- Build command used and its exit status.
- Updated documentation and ADRs.
- Known limitations and unimplemented parts.
- Dependency and license changes.
- A short summary of the acceptance criteria met and what remains.

## 14. Immediate M0 tasks

M0 is documentation, definition, and de-risking. No engine code.

1. Create the fixture set: three templates with data and the layout
   behaviour each one requires. Minimum: invoice, multi-page listing,
   grouped statement.
2. Record what each fixture needs in a one-page note per fixture. These
   notes, not the Crystal feature list, drive the schema.
3. Audit candidate dependencies and record the result in
   `docs/dependencies.md`, including rejected options and why.
4. Define the adapter contracts: text measurement, font resolution, image
   loading, resource resolution, PDF canvas. Signatures in
   `docs/architecture.md`; code comes in M1.
5. Define the render document contract (page, text run, image, line,
   rect, clip). This is the most expensive contract to change later.
6. Verify headless build and test invocation on this machine:
   `B4JBuilder.exe -Task=Build` on a console harness project. Record the
   exact command and the exit-code behaviour.
7. Confirm the project name and package prefix before the first public
   release. `Repot` reads as an official Anywhere Software library;
   decide deliberately and note it.
8. Present the fixture-driven schema outline for review before M1.

Begin M1 only after the M0 review.

### M0 status (2026-10-31)

| Task | Status |
|------|--------|
| Fixture set: three templates, data, parameters, notes | done |
| Fixture checker harness in `source/RepotTests` | done, 58 fixture checks passing |
| Negative test of the checker (injected faults) | done, all five faults reported |
| Headless build verification (B4J 10.7 / Java 19) | done, `-Task=Build` and `-Task=BuildLibrary` both exit `0` |
| Dependency audit (`docs/dependencies.md`) | draft; PDF and office jars still unverified |
| Adapter and render-document contracts (`docs/architecture.md`) | draft |
| Project name and package prefix | done: Repot (ADR 0007) |
| Fixture-driven schema review | open |

The schema change that came out of writing the fixtures: aggregates are
document-unique and referenced bare, and groups may declare their own
aggregates. See `fixtures/statement-grouped` and
`docs/template-format.md` §4.4.

### M1 status — core model (partial, 2026-10-31)

Implemented in `source/Repot` and exercised from `source/RepotTests`:

| Deliverable | Status |
|-------------|--------|
| Definition model: page, fonts, styles, parameters, datasets, groups, sections, elements | done |
| Unit conversion (pt/mm/cm/in, px with explicit DPI) and invariant number formatting | done |
| `.b4xr` loader with structured diagnostics and unknown-property warnings | done |
| Semantic validation: references, uniqueness, section rules, aggregates, resources | done |
| Expression reference scanner and identifier resolution (not evaluation) | done, parser/evaluator in M6 |
| Canonical JSON writer and load → save → reload round-trip | done |
| Dataset and parameter binding with typed-value checks | done |
| Engine unit tests in the headless harness | done, 108 checks |
| Adapter contracts and render document | not started |
| Layout, pagination, exporters | not started |

The whole harness currently reports 166 checks and zero errors:

```text
PASS invoice-basic (19 checks, 0 errors, 0 warnings)
PASS listing-multipage (17 checks, 0 errors, 0 warnings)
PASS statement-grouped (22 checks, 0 errors, 0 warnings)
PASS engine (108 checks)
fixtures=3 checks=166 errors=0
```

Build commands verified:

```text
cd source\Repot
B4JBuilder.exe -Task=Build          # console jar, exit 0
B4JBuilder.exe -Task=BuildLibrary   # Repot.jar + Repot.xml in %Additional%\B4J
```

Known M1 limitations:

- The M0 schema review is still open. The non-visual core was started
  first because it is fixture-driven and does not freeze the schema;
  layout must not start until the review is closed.
- `BuildLibrary` writes a jar and XML metadata to the B4J Additional
  folder; the `.b4xlib` packaging step is still M9 work.
- Expression validation is lexical. There is no parser, evaluator, or
  aggregate engine yet.
- `date` and `datetime` values are carried as supplied (string or ticks);
  conversion and formatting arrive with the expression and formatting
  work.
- Element-level `align` and `valign` were added because the fixtures use
  them; the schema draft is updated to match.
- The M0 schema review and the adapter/render-document contracts remain
  open, so M1 is deliberately scoped to the non-visual core.

---

## Appendix A — Principles to preserve

- One portable template; multiple output targets.
- B4X-first, not Java-first.
- B4J-first implementation with a platform-independent core.
- Visual layout and structured data export remain separate pipelines.
- The application owns data access; the template never does.
- MIT across the board; capability is never withheld.
- The layout model is specified and tested before the schema is frozen.
- No designer before the engine is stable.

## Appendix B — Terminology

| Term | Meaning |
|------|---------|
| Template | The `.b4xr` JSON file describing a report |
| Definition | The in-memory template model |
| Dataset | A named, host-supplied sequence of typed records |
| Band / section | A horizontal region of a report: header, detail, footer |
| Push-down | Shifting lower elements when a higher element grows |
| Render document | Immutable paginated display list consumed by exporters |
| Golden | A checked-in expected output used by regression tests |
| Adapter | Platform-specific implementation of a core interface |
