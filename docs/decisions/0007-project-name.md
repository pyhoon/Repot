# ADR 0007 — Project name: Repot

- Status: accepted
- Date: 2026-10-31

## Context

The working name `B4XReport` reads as an official Anywhere Software
library. Community libraries that start with `B4X` are indistinguishable
from shipped ones, and a commercial product using that prefix invites
both confusion and trademark friction. The name had to be fixed before M1
because it determines the `.b4xlib` filename, class prefixes, B4J project
names, the repository name, and every future import.

Constraints: must be valid in a URL and a filename, must not claim the
`B4X` namespace, must be distinct enough to search for, and must not
collide with an existing B4X library.

## Decision

The project is **Repot**.

- Public classes use the `Repot` prefix: `Repot`, `ReportResult`,
  `ReportDiagnostic`, `ReportPdf`, `ReportHtml`, `ReportCsv`, `ReportJson`,
  `ReportXml`, `ReportDocx`, `ReportXlsx`, `ReportB4JAdapter`,
  `ReportB4AAdapter`.
- The library file is `Repot.b4xlib`; the B4J projects are `Repot` and
  `RepotTests`.
- `[B4X]` is used only as a forum tag to signal the ecosystem, never as
  part of a class or file name.
- The template extension stays `.b4xr`, because it identifies the format,
  not the product.

## Consequences

- Repository, source paths, project files and documentation were renamed
  during M0. GitHub redirects the old repository URL after a rename.
- There is no compatibility burden: nothing has been released and no
  template exists outside this repository.
- The name is not semantically neutral. It is an English verb ("repot" a
  plant) and, in Malay and Indonesian, an adjective meaning troublesome.
  It was chosen by the maintainer for brevity and memorability. The
  practical cost is noisy searches, mitigated by always publishing it as
  "Repot — a reporting engine for B4X".
- Renaming again is cheap until the first `Repot.b4xlib` is published,
  and expensive afterwards. This ADR is the point of no return.

## Alternatives considered

- **Keep `B4XReport`.** Zero churn, but the official-namespace confusion
  is exactly the problem this ADR exists to solve. Rejected.
- **`B4XRpt`.** Keeps the prefix and is easy to search, but still implies
  official status. Rejected.
- **`AR_Report`.** Follows the community author-prefix convention
  (`AS_`, `SS_`) and has the lowest collision risk, but reads as a
  personal utility rather than a product. Rejected.
