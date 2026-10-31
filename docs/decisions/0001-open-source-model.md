# ADR 0001 — Open-source model: MIT for everything

- Status: accepted
- Date: 2026-10-31
- Supersedes: the public/commercial split in the original README and PLAN

## Context

The original plan proposed an MIT core with commercial DOCX, XLSX, ODF,
and designer components. Reviewing that against the actual B4X market
changed the conclusion:

- **The paywall was on the commodity.** Office formats are zip plus XML
  assembly. `jPOI` is already an official, free B4J library. The banded
  layout engine, pagination, and template format are the hard, defensible
  work — and those were on the free side.
- **The fee ceiling is small.** The B4X audience is a few thousand active
  developers at most. A reporting library realistically sells in the tens
  to low hundreds of copies, one-time, at low prices. That does not fund
  development and does not justify licensing infrastructure.
- **It cannot be enforced anyway.** A `.b4xlib` is a zip of readable
  `.bas` files, and B4X obfuscation does not cover B4X source. Any paid
  tier is honour-system with permanent friction for legitimate users.
- **The paywall distorted scope.** DOCX — the output prior art shows
  B4X developers reach for first — was deferred and gated, while XLSX and
  ODF, which almost nobody asked for, were commercial.
- **Adoption is the only compounding asset.** Examples, forum threads,
  third-party integrations, and possibly official-library attention all
  require a free base. Wrappers around paid Java engines already own the
  "commercial" niche, and they are losing on friction, not features.

## Decision

Everything in this repository is MIT: engine, layout, all exporters,
platform adapters, documentation, fixtures, and examples. There is no
commercial edition, no licence key, no activation, no telemetry, and no
capability reserved for a future paid product.

Money, if it ever appears, comes from sponsorship or paid integration
work under a separate agreement. A visual designer may be a separate
commercial application, but the engine must never be crippled to make it
attractive.

Contributions are accepted under DCO sign-off, inbound = outbound MIT.
No CLA.

## Consequences

- No licence revenue, ever, from the engine. Accepted deliberately.
- Published MIT code stays MIT. This is the one irreversible cost: the
  engine cannot be closed later. Future new modules could be treated
  differently, but the plan forbids withholding engine capability.
- Adoption, contributions, and goodwill become the return on investment.
- Support load must be bounded by an explicit best-effort policy, or the
  project becomes unpaid second-line support for other people's products.
- The README must not promise a paid tier or a roadmap shaped by one.

## Alternatives considered

- **Open core (original plan).** Splits effort across a public and a
  private tree, gates the wrong features, and the gated part is
  commodity. Loses.
- **AGPL plus commercial dual licence.** Would require a CLA, would be
  seen as a trap by a community that ships closed-source desktop apps, and
  there is no evidence of enterprise demand that would pay to avoid it.
  Loses.
- **Paid library, source included.** Unenforceable, suppresses adoption,
  and caps revenue below the cost of administering it. Loses.
- **Closed freeware.** No contributions, no ecosystem, still readable
  after decompilation. Loses.
