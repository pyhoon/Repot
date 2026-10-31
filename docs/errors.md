# Diagnostics

Status: M1 registry. Codes are stable strings. A code is never reused for a
different meaning; new checks get new codes.

Diagnostics carry a severity (`error` or `warning`), the code, a message,
a JSON pointer when the source is a template, and the element id when one
applies. Loading returns them in `RepotDiagnostics`; binding returns them
on `RepotDataBinder.Diagnostics`. Nothing is written to the console or
raised as a platform exception for an expected validation failure.

## 1. Prefixes

| Prefix | Area |
|--------|------|
| `E-IO-` | File access at the adapter boundary |
| `E-UNIT-` | Length and number conversion |
| `E-TPL-` | JSON shape, parsing and model construction |
| `E-VAL-` | Semantic validation of a loaded definition |
| `E-EXPR-` | Expression extraction and identifier resolution |
| `E-DATA-` | Dataset and parameter binding |
| `E-MEA-` | Text and font measurement at the platform adapter |
| `W-` | Warnings; rendering would still be possible |

## 2. File and units

| Code | Meaning |
|------|---------|
| `E-IO-001` | Template file cannot be read |
| `E-UNIT-001` | Length has no numeric part, an unknown unit, a bad decimal form, or uses `px` without an explicit DPI |

## 3. Template shape

| Code | Meaning |
|------|---------|
| `E-TPL-001` | Empty template or invalid JSON |
| `E-TPL-002` | Root is not a JSON object |
| `E-TPL-010` | `schemaVersion` missing |
| `E-TPL-011` | `schemaVersion` not supported by this build |
| `E-TPL-012` | Report `id` missing |
| `E-TPL-013` | Report `name` missing |
| `E-TPL-020` | `page` missing or not an object |
| `E-TPL-021` | `page.dpi` negative |
| `E-TPL-022` | `page.size` missing |
| `E-TPL-023` | Unknown named page size |
| `E-TPL-024` | `page.size` not a name or `[width, height]` |
| `E-TPL-025` | Page dimensions not positive |
| `E-TPL-026` | Orientation not `portrait` or `landscape` |
| `E-TPL-027` | `page.margins` missing |
| `E-TPL-028` | Negative page margin |
| `E-TPL-029` | Margins leave no content area |
| `E-TPL-030` | Negative grid column, row or cell size |
| `E-TPL-031` | Grid has no cell size and no row/column count |
| `E-TPL-040` | Font entry is not an object |
| `E-TPL-041` | Font family is not a string or string array |
| `E-TPL-042` | Font has no family |
| `E-TPL-043` | Font size not positive |
| `E-TPL-044` | Duplicate font name |
| `E-TPL-050` | Style entry is not an object |
| `E-TPL-051` | Style has no font reference |
| `E-TPL-052` | Duplicate style name |
| `E-TPL-060` | Parameter entry is not an object |
| `E-TPL-061` | Parameter has no name |
| `E-TPL-062` | Unknown parameter type |
| `E-TPL-063` | Duplicate parameter name |
| `E-TPL-070` | Dataset entry is not an object |
| `E-TPL-071` | Dataset kind not `rows` or `single` |
| `E-TPL-072` | Field entry is not an object |
| `E-TPL-073` | Field has no name |
| `E-TPL-074` | Duplicate field name in a dataset |
| `E-TPL-075` | Unknown field type |
| `E-TPL-076` | Dataset has no fields |
| `E-TPL-077` | Dataset has no name |
| `E-TPL-078` | Duplicate dataset name |
| `E-TPL-080` | Group entry is not an object |
| `E-TPL-081` | Sort entry is not an object |
| `E-TPL-082` | Sort entry has no field |
| `E-TPL-083` | Sort direction not `ascending` or `descending` |
| `E-TPL-084` | Group has no id |
| `E-TPL-085` | Duplicate group id |
| `E-TPL-090` | Aggregate entry is not an object |
| `E-TPL-091` | Aggregate has no name |
| `E-TPL-092` | Unknown aggregate function |
| `E-TPL-093` | Aggregate function requires a field |
| `E-TPL-100` | Section entry is not an object |
| `E-TPL-101` | Section height missing |
| `E-TPL-102` | Section has no type |
| `E-TPL-103` | Section has no id |
| `E-TPL-104` | Duplicate section id |
| `E-TPL-110` | Element entry is not an object |
| `E-TPL-111` | `bounds` is not an array |
| `E-TPL-112` | `bounds` does not have four entries |
| `E-TPL-113` | `cell` is not an object |
| `E-TPL-114` | `cell.col` or `cell.row` missing |
| `E-TPL-115` | `cell.colSpan` or `cell.rowSpan` below 1 |
| `E-TPL-116` | Element has no type |
| `E-TPL-117` | Element has no id |
| `E-TPL-120` | Required length property missing |

## 4. Semantic validation

| Code | Meaning |
|------|---------|
| `E-VAL-001` | Font has no family |
| `E-VAL-002` | Font size not positive |
| `E-VAL-010` | Style references an unknown font |
| `E-VAL-011` | Invalid style align |
| `E-VAL-012` | Invalid style valign |
| `E-VAL-013` | Invalid style overflow |
| `E-VAL-014` | Style line spacing not positive |
| `E-VAL-015` | Invalid style colour |
| `E-VAL-020` | Parameter has an unknown type |
| `E-VAL-030` | Dataset kind invalid |
| `E-VAL-031` | Dataset has no fields |
| `E-VAL-032` | Field has an unknown type |
| `E-VAL-040` | Group has no dataset |
| `E-VAL-041` | Group references an unknown dataset |
| `E-VAL-042` | Group has no key expression |
| `E-VAL-043` | Group sorts by an unknown field |
| `E-VAL-050` | Duplicate aggregate name |
| `E-VAL-051` | Aggregate has no dataset |
| `E-VAL-052` | Aggregate field does not exist |
| `E-VAL-060` | Page dimensions not positive |
| `E-VAL-061` | Margins leave no content area |
| `E-VAL-070` | No Detail section |
| `E-VAL-071` | Singleton section type repeated |
| `E-VAL-072` | Unknown section type |
| `E-VAL-073` | Negative section height |
| `E-VAL-074` | Invalid `pageBreak` |
| `E-VAL-080` | Detail section has no dataset |
| `E-VAL-081` | Detail section references an unknown dataset |
| `E-VAL-082` | Detail section references a group |
| `E-VAL-083` | Group section has no group |
| `E-VAL-084` | Group section references an unknown group |
| `E-VAL-085` | Group section sets `dataSet` |
| `E-VAL-086` | Non-detail section sets `dataSet` |
| `E-VAL-087` | Non-group section sets `group` |
| `E-VAL-090` | Duplicate element id |
| `E-VAL-091` | Unknown element type |
| `E-VAL-092` | Neither or both of `bounds` and `cell` |
| `E-VAL-093` | Negative bounds width or height |
| `E-VAL-094` | Cell exceeds the declared grid columns |
| `E-VAL-095` | Cell positioning has no grid size |
| `E-VAL-096` | Unknown element style |
| `E-VAL-097` | Text element has a value expression |
| `E-VAL-098` | Field element has no value expression |
| `E-VAL-099` | Field element has static text |
| `E-VAL-100` | Image element has no resource |
| `E-VAL-101` | Image resource is absolute or escapes the template folder |
| `E-VAL-102` | Image resource file is missing |
| `E-VAL-103` | Invalid image fit |
| `E-VAL-104` | Negative line width |
| `E-VAL-105` | Negative rectangle radius |
| `E-VAL-106` | Invalid element colour or fill |
| `E-VAL-107` | Invalid element align or valign override |

## 5. Expressions

| Code | Meaning |
|------|---------|
| `E-EXPR-001` | Unexpected character in an expression |
| `E-EXPR-002` | Unbalanced brace |
| `E-EXPR-003` | Empty expression |
| `E-EXPR-004` | Unterminated string literal |
| `E-EXPR-010` | Unknown parameter reference |
| `E-EXPR-011` | Unknown dataset in a dotted reference |
| `E-EXPR-012` | Unknown field or aggregate in a dotted reference |
| `E-EXPR-013` | Unknown bare identifier |
| `E-EXPR-014` | Ambiguous bare identifier |

M1 resolves identifiers only. Evaluation diagnostics are added in M6.

## 6. Binding

| Code | Meaning |
|------|---------|
| `E-DATA-001` | List supplied for a `single` dataset |
| `E-DATA-002` | Dataset source is null/empty |
| `E-DATA-003` | Row is not an object |
| `E-DATA-004` | Single record supplied for a `rows` dataset |
| `E-DATA-010` | Declared dataset was not supplied |
| `E-DATA-011` | Required parameter missing or null |
| `E-DATA-020` | Value does not match the declared type |
| `E-DATA-021` | Integer field received a fractional value |
| `E-DATA-022` | Declared type is unknown |

## 7. Measurement

| Code | Meaning |
|------|---------|
| `E-MEA-001` | The platform measurement adapter cannot be initialised |
| `E-MEA-002` | Font vertical metrics cannot be read |
| `E-MEA-003` | A specific string cannot be laid out |
| `E-MEA-004` | A text block exceeds the adapter's line limit |

## 8. Warnings

| Code | Meaning |
|------|---------|
| `W-TPL-001` | Unknown optional template property ignored |
| `W-VAL-001` | Empty text element |
| `W-DATA-001` | Undeclared dataset supplied; ignored |
| `W-DATA-002` | Undeclared parameter supplied |
| `W-DATA-003` | Undeclared record field ignored |
| `W-MEA-001` | A requested font family was unavailable and another family was used |
