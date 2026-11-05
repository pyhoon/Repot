# ADR 0010 — File extension: `.repot` (was `.b4xr`)

- Status: accepted
- Date: 2026-11-05

## Context

The project was renamed from `B4XReport` to `Repot` per ADR 0007. The template
file extension `.b4xr` explicitly associates the format with the `B4X`
ecosystem brand. Since the library is under private development and never
released, the extension can be updated to be meaningful to the project name
without compatibility burden on external users.

The extension serves as a format identifier for the template loader; it should
reflect the project name rather than the originating ecosystem.

## Decision

The template file extension is **`.repot`** (replacing `.b4xr`).

- All `.b4xr` fixture templates are renamed to `.repot`.
- The template loader accepts both `.b4xr` and `.repot` during a deprecation
  window, then `.repot` exclusively after the window closes.
- Existing `.b4xr` templates continue to load during the deprecation window
  (until M8), after which only `.repot` is supported.
- The template schema (`schemaVersion`, element types, render-document contract)
  is unchanged; only the file extension changes.

## Consequences

- **Positive:** Extension is consistent with project name `Repot`; no B4X
  namespace implication in file names; clearer for new adopters.
- **Negative:** Requires renaming 3 fixture templates, updating ~15 source
  code references, and updating ~7 documentation files. All `.b4xr` files
  must be renamed to `.repot` before the deprecation window closes.
- **Mitigation:** Since the library is private-development-only and never
  released, there are no external users affected. The deprecation window
  approach avoids breaking changes at any single point.

## Superseded ADRs

- **ADR 0005** — Own `.b4xr` JSON format: extension meaning is updated from
  `.b4xr` to `.repot`. Schema and format contract remain; only the extension
  changes.
- **ADR 0007** — Project name: Repot: the extension now aligns with the
  project name rather than staying `.b4xr` as a format identifier.

## Implemented by

- Renaming `fixtures/*/template.b4xr` → `fixtures/*/template.repot`
- Updating `ReportTemplateLoader.bas` to accept `.repot` (and `.b4xr` during
  deprecation window)
- Updating `ReportEngineTests.bas` test calls
- Updating documentation files referencing `.b4xr`
- All builds and fixture checks pass with `.repot` extension