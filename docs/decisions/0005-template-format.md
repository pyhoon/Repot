# ADR 0005 — Own `.b4xr` JSON format, schema frozen last

- Status: accepted
- Date: 2026-10-31

## Context

The template format is the project's real compatibility contract. It must
be portable, diffable, tool-friendly, and stable enough that a designer
can be built on it. Options:

- **Own JSON format (`.b4xr`).** Full control, readable diffs, easy for
  tooling and language models, no licence entanglement. Cost: we define
  and maintain everything, and there is no existing designer.
- **Adopt a JRXML subset.** JasperReports already has a free visual
  designer (Jaspersoft Studio) and a large body of examples. Cost: JRXML is
  verbose XML, Java-typed expressions, band semantics we would have to
  emulate, and the designer itself is EPL and cannot be bundled. We would
  inherit a document model we do not control, and still implement the
  engine.
- **HTML templates.** Attractive for web output, useless for
  deterministic pagination across PDF, print, and Android.
- **Crystal `.rpt`.** Proprietary and effectively unreadable.

The schema itself is also a scheduling question: freezing it early locks
in guesses, and every field costs migrations later.

## Decision

Use a JSON format with the `.b4xr` extension, owned by this project.
Freeze the schema **last**, driven by the fixture set: three real reports
first, schema second. Expressions are braced and evaluated by a small
hand-written grammar. Templates never contain SQL, script, or executable
content.

Unknown optional properties warn and are ignored; unknown element or
section types are a hard error. `schemaVersion` is a `major.minor` string
with a documented migration path for majors.

## Consequences

- We must eventually build the designer ourselves, or accept that
  hand-edited JSON and programmatic construction are the only authoring
  paths for a while.
- No ecosystem of existing templates to import.
- JSON is readable by humans, diffs cleanly in git, and is easy for
  tooling, including AI assistants, to generate and inspect.
- Every schema addition is our migration to carry. Hence the "fixtures
  first" rule and the requirement for an ADR before schema changes.
- A JRXML *importer* remains possible later without adopting JRXML as the
  internal model.

## Alternatives considered

- **JRXML subset.** Solves the designer problem for free but imports a
  large, Java-flavoured specification, an expression language tied to Java
  types, and a document model aimed at a different engine. The saved
  designer effort is smaller than the cost of emulation. Rejected for 1.0;
  reconsider only if a real JRXML importer is requested.
- **XSL-FO.** Standard, but requires an FO processor (FOP) and a second
  layout engine. Rejected.
- **Freeze the schema now.** Cheaper in the short term, expensive when
  fixtures demand different primitives. Rejected.
- **Embed a scripting language for expressions.** Convenient, unsafe,
  non-deterministic across platforms. Rejected.
