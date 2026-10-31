# Architecture Decision Records

An ADR is written when a decision is expensive to reverse: the template
schema, the layout model, the render document contract, dependencies,
packaging, licensing, or the public API. ADRs are immutable once
accepted; a later ADR supersedes an earlier one.

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-open-source-model.md) | Open-source model: MIT for everything | accepted | 2026-10-31 |
| [0002](0002-layout-model.md) | Banded sections with optional grid snapping | accepted | 2026-10-31 |
| [0003](0003-pdf-backend.md) | PDF canvas interface with PDFBox backend | accepted | 2026-10-31 |
| [0004](0004-b4a-output-strategy.md) | B4A after B4J, HTML print path | accepted | 2026-10-31 |
| [0005](0005-template-format.md) | Own `.b4xr` JSON format, schema frozen last | accepted | 2026-10-31 |
| [0006](0006-packaging.md) | One `.b4xlib`, optional jars | accepted | 2026-10-31 |
| [0007](0007-project-name.md) | Project name: Repot | accepted | 2026-10-31 |

## Template

```markdown
# ADR NNNN — Title

- Status: proposed | accepted | superseded by ADR XXXX
- Date: YYYY-MM-DD
- Deciders: name(s)

## Context
What forces are at play. What breaks if nothing is decided.

## Decision
One paragraph, in the active voice.

## Consequences
What becomes easier, what becomes harder, what must now be maintained.

## Alternatives considered
Each option, and why it lost.
```
