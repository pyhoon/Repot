# B4X API Notes

Facts about the B4X toolchain that were **verified by compiling and
running code on this project**, not recalled from memory. The purpose is
to stop agents and contributors inventing APIs that do not exist.

Rule: add an entry only after verifying it, and say how. Anything not
listed here is unverified; check the B4X documentation or the installed
`Libraries` folder before using it.

## Environment used for verification

Recorded 2026-10-31, author's machine. This is a reference point, not a
project requirement.

| Item | Value |
|------|-------|
| B4J IDE | 10.7 (`B4J.exe` 10.7.0.0) |
| B4JBuilder | reports `B4JBuilder v10.70` |
| Java used by B4J | 19, `C:\Java\jdk-19.0.2\bin` (from `b4xV5.ini`) |
| B4J install | `C:\Program Files\B4X\B4J` |
| Additional libraries | `C:\B4X\Additional` |

## Building without the IDE

```text
cd <project folder>
"C:\Program Files\B4X\B4J\B4JBuilder.exe" -Task=Build
```

- Exit code `0` on success, `1` on failure. Verified on the fixture
  checker project.
- The jar is written to `Objects\<ProjectName>.jar`.
- Failure output includes the B4X source line number and the generated
  Java line, which is enough to fix most mistakes without opening the IDE.
- `-BaseFolder`, `-Project`, `-Configuration`, `-Output`, `-NoClean`,
  `-Obfuscate`, `-ShowWarnings`, and `-Task=BuildLibrary` are advertised
  by the builder. `-Task=BuildLibrary` is now verified separately above.
  The other switches are unverified; verify before relying on them.

## Building a library without the IDE

`-Task=BuildLibrary` is verified on the engine project with B4J 10.7 and
Java 19:

```text
cd <project folder>
"C:\Program Files\B4X\B4J\B4JBuilder.exe" -Task=BuildLibrary
```

- Requires `#LibraryName:` in the project file. Without it the builder
  exits `1` with `#LibraryName attribute must be set`.
- `#LibraryVersion:` must be a numeric value such as `0.10`; `0.1.0` is
  rejected as a format error.
- Exit code `0` on success.
- Writes `<LibraryName>.jar` and `<LibraryName>.xml` to the B4J
  Additional folder (`%Additional%\B4J`, here `C:\B4X\Additional\B4J`),
  not to the project and not as a `.b4xlib`. Package the `.b4xlib`
  separately.
- `-Output` did not change where the library files were written in this
  verification.

## Modules and relative references

- A module file is a `.bas` file next to the project file, listed as
  `ModuleN=Name`.
- `ModuleN=|relative|..\OtherProject\ModuleName` works and is how
  `source/RepotTests` compiles the engine modules without copying them.
- Class modules require `Sub Class_Globals ... End Sub` before their
  fields.
- Code modules require `Sub Process_Globals ... End Sub` before their
  fields. A `Type=Code` module with no globals still needs an empty
  `Process_Globals`.
- `Private Const` and `Public Const` belong inside the relevant globals
  block.
- A console project needs `#MergeLibraries: True` to run its jar without
  an external `libs` folder. `BuildLibrary` ignores the setting.

## Console application shape

- `AppType=StandardJava`.
- Code can live inline in the `.b4j` file after `@EndOfDesignText@`.
  A single-file console project works with `NumberOfModules=0` and
  `NumberOfFiles=0`.
- Entry point: `Sub AppStart (Args() As String)`. Command-line arguments
  arrive as `Args()`.
- Libraries are declared with `LibraryN=<name>` and must be matched by
  `NumberOfLibraries`. Core is `jcore`.
- **A console app cannot set its process exit code.** `Log` and a written
  result file are the reliable signals. A wrapper script must translate
  that into an exit code (see `tools/run-fixtures.ps1`).

## JSON

JSON is **not** part of `jcore`. Add the library:

```text
Library2=json
```

The object is `JSONParser`, not `Json`:

```vb
Dim parser As JSONParser
parser.Initialize(Text)
Dim m As Map = parser.NextObject      ' object at the top level
Dim l As List = parser.NextArray      ' array at the top level
```

- `Json.Parse` does not exist in B4J. Using `Json` compiles to
  "Undeclared variable 'json'".
- Whole numbers may arrive as `Integer` or `Double` depending on the
  value. Test with `IsNumber(o)`, then assign to the target type
  (`Dim i As Int = o`).
- Parsing throws on malformed input; wrap in `Try`/`Catch`.
- There is no JSON writer in this library. Build output JSON yourself if
  a tool needs it, or write a line-based format instead.

## Strings

- **`String.Split` does not exist.** Tokenise with a manual scan or with
  `Regex` (verify the Regex library separately). This surprises people
  coming from .NET or Java.
- Available and verified: `SubString2(Start, EndExclusive)`,
  `SubString(Start)`, `IndexOf(Search)`, `Trim`, `ToLowerCase`,
  `Length`.
- `StartsWith`/`EndsWith` were avoided rather than assumed. Use
  `SubString2` with a length check if you need them.

## Files

- Verified: `ReadString(Dir, Name)`, `WriteString(Dir, Name, Text)`,
  `Exists(Dir, Name)`, `ListFiles(Dir)`, `Combine(Dir, Name)`,
  `DirApp`.
- **`File.AppendString` does not exist.** Read, concatenate, write.
- `File.DirApp` is **not** reliably "the folder containing the jar": when
  the jar is launched with a relative path, it resolves from the process
  working directory. This was caught by a result file appearing in the
  project folder instead of `Objects\`. Pass an explicit output folder
  (the fixture checker takes one as its second argument).

## Language features confirmed while building the harness

- `Try` / `Catch` / `End Try`.
- `Continue` inside `For Each` and `Do While`.
- `Is` for `Map`, `List`, `String`, `Boolean`.
- `IsNumber(o)` accepts an `Object` and returns `False` for booleans.
- `Dim a() As String = Array As String("x", "y")`.
- Typed iteration: `For Each s As String In list`.
- `List.Sort(True)`, `List.IndexOf(value)`, `List.Size`.
- `Map.Keys`, `Map.ContainsKey`, `Map.Get`, `Map.Put`.
- `StringBuilder.Length` and `StringBuilder.ToString`.

## Still unverified — check before use

Do not write code against these until they are confirmed and moved into a
verified section:

- `XmlBuilder` availability and API per platform.
- Zip/`Archiver` support for the office-document writer.
- XUI image loading and bitmap access from a headless B4J app.
- Font enumeration and text measurement outside a UI.
- PDFBox classes and the B4J wrapper jar layout.
- Anything Android-specific: `WebView` printing, `PrintDocumentAdapter`,
  `PdfDocument`, minimum API level.
- `ExitApplication` semantics in a console app.

## Language gotchas found in M1

- **`Map.Keys` is not a `List` for assignment purposes.** Iterating it
  with `For Each k As String In m.Keys` works. `Dim keys As List =
  m.Keys` compiles but fails at runtime with
  `ClassCastException: Map$IterableMap cannot be cast to List`. Copy the
  keys into a new `List` when sorting is needed.
- **`Quote` is a reserved word.** It cannot be a sub, variable, or
  parameter name. `RepotJsonUtil.JsonQuote` is used instead.
- **`Return Not X` is a syntax error.** Use
  `If X Then Return False` / `Return True`.
- **`Function` is not a B4X keyword.** All subs return with `Sub ... As
  Type` and end with `End Sub`.
- `String.Replace(Search, Replacement)` works and was used by the M1
  negative tests.
- `Floor`, `Round`, `Abs`, `Asc`, and `Chr` are available. `Round` can be
  assigned to an integer or long target.
- `Dim d As Long = Round(value)` compiles and runs.
- `Private Const` must be inside `Class_Globals` for a class module; it
  cannot sit loose between subs.

## Why this file exists

`PLAN.md` forbids inventing B4X APIs. Two compile failures during M0 were
caused by assumed APIs (`Json` and `String.Split`). Each such assumption
costs a build cycle and, worse, can produce documentation that is wrong
for months. Record the verified fact once.
