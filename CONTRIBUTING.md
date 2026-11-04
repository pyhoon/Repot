# Contributing to Repot

## License of contributions

Repot is MIT-licensed, and it will stay that way. By submitting a
contribution you agree that it is licensed under the same MIT terms as the
rest of the project.

Contributions must carry a Developer Certificate of Origin (DCO)
sign-off:

```text
Signed-off-by: Your Name <your@email>
```

Use `git commit -s` to add it. There is no CLA and no copyright
assignment. If you are not comfortable with MIT licensing, do not
contribute code; opening an issue with the idea is still welcome.

## Before you write code

1. Read `README.md`, `PLAN.md`, and the document covering the area you
   want to touch. Layout work means `docs/layout.md`. Format work means
   `docs/dependencies.md` and the relevant ADR.
2. Open an issue describing the change. Small fixes can go straight to a
   pull request.
3. If the change touches the template schema, the layout model, the
   render document contract, or the public API, propose an ADR first.
   Those are the expensive contracts.

## What gets accepted

Likely to be accepted:

- Bug fixes with a regression fixture.
- New fixtures and data sets that expose real-world layout problems.
- Documentation corrections.
- Additional exporters that follow the render document contract and ship
  with tests.
- Platform adapters that do not leak platform types into the core.

Likely to be declined:

- New third-party dependencies without an entry in
  `docs/dependencies.md`.
- Anything AGPL, anything requiring native binaries, anything spawning
  external processes.
- Database access, SQL parsing, or network calls inside the engine.
- Scripting or expression evaluation outside the documented grammar.
- UI work (designer, viewer) before the engine is stable.
- Licence, activation, or telemetry code. None of that belongs here.
- Large refactors with no behavioural or test justification.

## Code expectations

- B4X-native code and collections. No Java unless it is inside a clearly
  marked platform adapter or `#If Java` block, with a comment explaining
  why and which platforms it targets.
- No JavaFX, Android UI, DOM, or server request types in core, layout, or
  processing.
- Public subs get a one-line comment stating contract and threading
  expectations.
- Every feature ships with a test or fixture. Layout changes require a
  golden update and a note explaining the visual difference.
- Keep the public API smaller than you want to.

## Build and test

The engine is developed in B4J. Headless builds use the official
command-line builder:

```text
cd <project folder>
B4JBuilder.exe -Task=Build
```

Record the exact command in the pull request and confirm the exit code.
Prefer `-Task=Build`; `-Task=BuildLibrary` installs `Repot.jar`/`Repot.xml`
into the additional libraries folder and shadows the source `.b4xlib`. See
`docs/testing.md` for the fixture harness and what a valid golden change
looks like.

## Review and support

Maintenance is best-effort by the author. There is no SLA, no guaranteed
response time, and no private support channel. Issues and pull requests
may sit for a while; that is not a rejection.

If you need guaranteed turnaround, dedicated help, or integration work,
arrange it separately as paid work. Paid work never influences what goes
into the MIT release, and no feature is withheld for it.

## Reporting security issues

Report suspected vulnerabilities privately to the maintainer rather than
in a public issue, especially anything involving resource path handling,
template parsing, or unbounded memory use. There is no bug bounty.

## Style

- British spelling in documentation, consistent with existing files.
- Hard-wrap prose near 76 columns; do not reflow unrelated lines.
- Dates as `YYYY-MM-DD`.
- ADR filenames are `NNNN-short-title.md`, numbered consecutively.
