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
| B4ABuilder | reports `B4ABuilder v14.20` |
| B4A install | `C:\Program Files\B4X\B4A` |
| Android SDK | android-36 (verified on emulator-5554) |
| adb | `C:\android\sdk\platform-tools\adb.exe` |

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

## Building for B4A without the IDE

Verified in M8 against the engine library project and the B4A test suite:

```text
cd <project folder>
"C:\Program Files\B4X\B4A\B4ABuilder.exe" -task=Build -obfuscate=False
```

- Exit code `0` on success, `1` on failure.
- The APK is written to `Objects\<ProjectName>.apk`.
- The builder auto-finds the single `.b4a` file in the current folder;
  there is no need to name the project file.
- **Do not pass `-Project`.** B4JBuilder accepts it; on B4ABuilder it
  mis-parses and the run fails before the build starts. Passing extra
  switches such as `-xmaxerrs` is also rejected.
- When run from PowerShell, error output appears twice (PowerShell
  echoes the error stream); filtering with `Select-String` for
  `Error description` / `Word:` finds the real diagnostics.
- Failures include the module and line number, as on B4J.

## B4A facts verified in M8

- **`|relative|` paths resolve against the project folder** (BaseFolder),
  not against the folder of the file that contains the reference. A
  module reference `|relative|..\ReportEngineTests` inside a file in
  `tests\B4A\` resolves to `tests\ReportEngineTests`, one level up from
  the project folder.
- **`#If B4A` / `#If B4J` are evaluated by the builder target, per
  module.** The platform flag in a `.bas` file header (`B4J=true` etc.)
  does not suppress target conditionals inside that file's code; only
  the file's own inclusion in a project decides whether its header flag
  applies. Write conditionals in the module body and expect both builder
  targets to process each included module.
- **`#If Java` lambdas break the Android dexer.** Java code containing
  lambda expressions compiles but fails at dexing ("cannot desugar").
  All inline Java helpers must be lambda-free — use explicit
  anonymous inner classes, or avoid the construct.
- **`File` member gaps on B4A** (exist on B4J): `GetFileParent`,
  `GetName`, `DirApp`, `DirAppData`. Do not use them in shared modules;
  on B4A use `File.DirInternal` for test/output files. If the full path
  of a written file is needed, derive it by string splitting from the
  output path, not from a `File` helper.
- **`File.ListFiles` fails on an asset folder.** To read bundled fixture
  assets, copy a known, hardcoded list of asset names to internal
  storage (`File.Copy(AssetsDir, name, True, DirInternal, name)`) and
  read from internal storage.
- `File.Combine(Dir, Name)` returns the literal
  `"AssetsDir/fixtures/name"` for an asset path — it is a display-style
  string, not a usable absolute path.
- **`JavaObject` and derived class names.** Wrapping a class whose
  runtime package is rewritten by the B4A compiler (e.g.
  `b4j.example.*`) with `JavaObject.InitializeStatic` or a literal class
  name throws `ClassNotFoundException` on B4A. Wrap the calling module
  itself with `jo.Initialize(Me)` and let the runtime resolve the own
  class.
- **JavaObject float argument matching.** When calling a Java method
  that takes a `float`, pass a value held in a `Dim x As Float`
  variable; a raw literal may arrive as a `Double` and fail the
  reflection lookup.
- **`android.graphics.Paint` measurement**: `Paint.setTextSize` needs
  the explicit-float treatment above; measure at a base size of 1000 and
  scale linearly (same trick as AWT integers, but here it avoids float
  rounding); `Paint.FontMetrics` reports **ascent as a negative value**
  — negate it to get a positive ascent.
- **Typeface family resolution is silent on B4A.**
  `Typeface.create(family, style)` falls back to the default family for
  any unknown name; no warning is printed. The engine maps unknown
  families to `sans-serif` and raises its own `W-MEA-001` warning. The
  builtin family set includes `sans-serif`, `serif`, `monospace`,
  `cursive`, `sans-serif-condensed` and legacy aliases `sansserif` /
  `monospaced` (B4J uses `Dialog` as the substitution target).
- **Log viewer truncates long lines.** `Log` output needed for diagnostics
  is padded/prefix-limited in the logs; write detailed results to a file
  (`File.WriteString(DirInternal, ...)`) and mirror a short summary to
  the log.
- **`.b4xlib` manifest `Version` must be a two-part numeric value**
  (e.g. `1.0`). A three-part value (`1.0.0`) is rejected with
  `Input string was not in a correct format` when the library is used.
  The in-code `ReportVersion.LibraryVersion` string is unaffected and may
  use three parts.
- Deployment loop (emulator-5554): build →
  `<adb> install -r Tests.apk` → `am force-stop` → `logcat -c` →
  `am start -n b4a.example/.main` → wait for the run → `logcat -d` and
  filter for the PASSED/FAILED summary lines.


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
- A class sub may return another class instance, and the caller may assign
  it directly: `Dim p As ReportRenderPage = doc.AddPage(w, h)`. Verified by
  the render-document tests.
- A no-argument sub may be declared without parentheses
  (`Public Sub AddRestore As ReportDrawOp`) and called as
  `page.AddRestore`. Verified by the same tests.
- **Headless AWT text measurement works through `JavaObject`** when only
  public `java.awt` APIs are used. `Font`, `FontRenderContext` and
  `TextLayout` need `LibraryN=JavaObject`. Do not call `createGraphics` or
  `getFontMetrics`: the returned `sun.java2d.SunGraphics2D` cannot be
  wrapped (`IllegalAccessException`, module `java.desktop` does not export
  `sun.java2d`). `getLineMetrics` fails the same way because the runtime
  class is `sun.font.FontLineMetrics`; `TextLayout.getAscent`,
  `getDescent`, `getLeading` and `getAdvance` are the public replacement.
- **Static fields are not reachable through `JavaObject.InitializeStatic`.**
  `GetField` inspects the wrapped `java.lang.Class` object, not the class
  it represents. `RenderingHints.VALUE_TEXT_ANTIALIAS_ON` and
  `VALUE_FRACTIONALMETRICS_ON` are obtained from an instance:
  `New RenderingHints(New HashMap)` then `GetField`.
- **AWT `Font` sizes are integers.** `Font(String, int, int)` rounds, and
  `deriveFont(float)` is not matched by `JavaObject` because B4X passes a
  `Double`. Measure at 1000 pt and scale linearly for fractional sizes.

## Still unverified — check before use

Do not write code against these until they are confirmed and moved into a
verified section:

- `XmlBuilder` availability and API per platform.
- Zip/`Archiver` support for the office-document writer.
- XUI image loading and bitmap access from a headless B4J app.
- PDFBox classes and the B4J wrapper jar layout.
- Android WebView printing: verified on API 36 (emulator-5554):
  - `Context.getSystemService("print")` returns a non-null
    `android.print.PrintManager`.
  - `WebView.createPrintDocumentAdapter(String)` returns a non-null
    `PrintDocumentAdapter` (verified via JavaObject).
  - `android.print.PrintAttributes.Builder` is a nested class, not a
    static method: instantiate with
    `jo.InitializeNewInstance("android.print.PrintAttributes$Builder", ...)`.
  - Driving the adapter to a file programmatically requires calling
    `onLayout`/`onWrite` with callback interfaces (see M10).
- PDFBox on Android (`PdfBox-Android`): not planned for v1.x.
- `ExitApplication` semantics in a console app.

## Language gotchas found in M1

- **A local `For Each` variable cannot shadow a class field.** A loop
  such as `For Each name As String In DataSets.Keys` inside a class that
  declares `Public Name As String` produces
  `Current declaration does not match previous one. Word: _ref` in the
  IDE compiler. Rename the loop variable (`dsName`). B4JBuilder may not
  report this before the IDE does.
- **`Map.Keys` is not a `List` for assignment purposes.** Iterating it
  with `For Each k As String In m.Keys` works. `Dim keys As List =
  m.Keys` compiles but fails at runtime with
  `ClassCastException: Map$IterableMap cannot be cast to List`. Copy the
  keys into a new `List` when sorting is needed.
- **`Quote` is a reserved word.** It cannot be a sub, variable, or
  parameter name. `ReportJsonUtil.JsonQuote` is used instead.
- **`asc` is a reserved word.** It cannot be a variable or parameter
  name (it is the built-in for character code). Use `ascentPx`.
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
