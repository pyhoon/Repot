# Template Format (`.b4xr`)

Status: **draft v0.1, not stable.** This schema will change. It is
frozen only after the fixture set in `fixtures/` renders correctly
through the real engine. See
[decisions/0005-template-format.md](decisions/0005-template-format.md).

## 1. Conventions

- UTF-8 JSON, extension `.b4xr`, no BOM, LF or CRLF both accepted.
- `schemaVersion` is a string and is required.
- Units are points unless a property says otherwise. `mm`, `in`, and `px`
  are accepted as suffixed strings and converted at load time.
- Identifiers are stable strings matching `^[A-Za-z][A-Za-z0-9_.-]*$`.
  They are referenced by tests, logs, and the designer. Never renumber
  them.
- Unknown **optional** properties are ignored with a warning. Unknown
  **structural** properties (a section type or element type the engine
  does not implement) are an error with a diagnostic.
- No JavaScript, no SQL, no file paths resolved outside the template
  directory, no network resources.

## 2. Top-level structure

| Property | Required | Purpose |
|----------|----------|---------|
| `schemaVersion` | yes | Format version, e.g. `"0.1"` |
| `id` | yes | Stable report identifier |
| `name` | yes | Human-readable name |
| `description` | no | Free text |
| `page` | yes | Size, orientation, margins, optional grid |
| `fonts` | no | Named font sets and fallbacks |
| `styles` | no | Named text and border styles |
| `parameters` | no | Typed values supplied by the host application |
| `dataSets` | no | Named datasets, fields, aggregates |
| `groups` | no | Grouping and sort declarations |
| `sections` | yes | Ordered band list |
| `metadata` | no | Author, version, notes; ignored by layout |

## 3. Example

A complete, if minimal, invoice. It is illustrative and is expected to
change as fixtures are added.

```json
{
  "schemaVersion": "0.1",
  "id": "invoice.standard",
  "name": "Standard invoice",
  "description": "One-page invoice with logo, line items and totals.",
  "page": {
    "size": "A4",
    "orientation": "portrait",
    "margins": { "top": "12mm", "right": "15mm", "bottom": "18mm", "left": "15mm" },
    "grid": { "columns": 40, "rows": 27 }
  },
  "fonts": {
    "body": { "family": ["DejaVu Sans", "Arial", "sans-serif"], "size": 9 },
    "mono": { "family": ["DejaVu Sans Mono", "monospace"], "size": 9 }
  },
  "styles": {
    "title": { "font": "body", "size": 18, "bold": true },
    "label": { "font": "body", "colour": "#555555" },
    "cell": { "font": "body", "valign": "middle", "overflow": "grow" },
    "cellRight": { "font": "body", "align": "right", "valign": "middle", "overflow": "grow" },
    "money": { "font": "body", "align": "right", "format": { "type": "number", "decimals": 2, "grouping": true } },
    "total": { "font": "body", "size": 11, "bold": true, "align": "right" }
  },
  "parameters": [
    { "name": "InvoiceNumber", "type": "string", "required": true },
    { "name": "IssuedOn", "type": "datetime", "required": true }
  ],
  "dataSets": [
    {
      "name": "Customer",
      "kind": "single",
      "fields": [
        { "name": "Name", "type": "string" },
        { "name": "Address", "type": "string" }
      ]
    },
    {
      "name": "Items",
      "kind": "rows",
      "fields": [
        { "name": "Description", "type": "string" },
        { "name": "Quantity", "type": "decimal" },
        { "name": "UnitPrice", "type": "decimal" },
        { "name": "Amount", "type": "decimal" }
      ],
      "aggregates": [
        { "name": "NetTotal", "function": "sum", "field": "Amount" },
        { "name": "LineCount", "function": "count" }
      ]
    }
  ],
  "sections": [
    {
      "type": "ReportHeader",
      "id": "report-header",
      "height": 90,
      "elements": [
        {
          "type": "image",
          "id": "logo",
          "bounds": [0, 0, 130, 48],
          "resource": "logo.png",
          "fit": "contain"
        },
        { "type": "text", "id": "title", "bounds": [360, 0, 150, 26], "style": "title", "text": "INVOICE" },
        { "type": "text", "id": "lbl-invoice-no", "bounds": [360, 30, 70, 14], "style": "label", "text": "Number" },
        { "type": "field", "id": "fld-invoice-no", "bounds": [430, 30, 80, 14], "style": "cellRight", "value": "{param.InvoiceNumber}" },
        { "type": "text", "id": "lbl-issued", "bounds": [360, 46, 70, 14], "style": "label", "text": "Issued" },
        { "type": "field", "id": "fld-issued", "bounds": [430, 46, 80, 14], "style": "cellRight",
          "value": "{param.IssuedOn}", "format": { "type": "date", "pattern": "yyyy-MM-dd" } }
      ]
    },
    {
      "type": "PageHeader",
      "id": "page-header",
      "height": 20,
      "elements": [
        { "type": "text", "id": "col-desc", "bounds": [0, 0, 240, 14], "style": "label", "text": "Description" },
        { "type": "text", "id": "col-qty", "bounds": [250, 0, 44, 14], "style": "label", "text": "Qty", "align": "right" },
        { "type": "text", "id": "col-price", "bounds": [300, 0, 100, 14], "style": "label", "text": "Unit price", "align": "right" },
        { "type": "text", "id": "col-amount", "bounds": [410, 0, 100, 14], "style": "label", "text": "Amount", "align": "right" },
        { "type": "line", "id": "header-rule", "bounds": [0, 17, 510, 0], "colour": "#999999", "width": 0.5 }
      ]
    },
    {
      "type": "Detail",
      "id": "detail",
      "dataSet": "Items",
      "height": 16,
      "elements": [
        { "type": "field", "id": "cell-desc", "bounds": [0, 0, 240, 16], "style": "cell", "value": "{Description}" },
        { "type": "field", "id": "cell-qty", "bounds": [250, 0, 44, 16], "style": "cellRight", "value": "{Quantity}" },
        { "type": "field", "id": "cell-price", "bounds": [300, 0, 100, 16], "style": "money", "value": "{UnitPrice}" },
        { "type": "field", "id": "cell-amount", "bounds": [410, 0, 100, 16], "style": "money", "value": "{Amount}" }
      ]
    },
    {
      "type": "ReportFooter",
      "id": "report-footer",
      "height": 40,
      "keepTogether": true,
      "elements": [
        { "type": "text", "id": "lbl-total", "bounds": [300, 6, 100, 16], "style": "total", "text": "Total" },
        { "type": "field", "id": "fld-total", "bounds": [410, 6, 100, 16], "style": "total", "value": "{NetTotal}" },
        { "type": "field", "id": "lbl-lines", "bounds": [0, 6, 200, 16], "style": "label", "value": "Items: {LineCount}" }
      ]
    },
    {
      "type": "PageFooter",
      "id": "page-footer",
      "height": 24,
      "elements": [
        { "type": "text", "id": "page-no", "bounds": [0, 8, 200, 12], "style": "label", "value": "Page {page.number} of {page.count}" },
        { "type": "field", "id": "customer", "bounds": [310, 8, 200, 12], "style": "label", "align": "right", "value": "{Customer.Name}" }
      ]
    }
  ]
}
```

## 4. Property reference

### 4.1 `page`

| Property | Type | Notes |
|----------|------|-------|
| `size` | string or `[w, h]` | `A4`, `A5`, `Letter`, `Legal`, or explicit dimensions |
| `orientation` | `portrait` \| `landscape` | Applied after `size` |
| `margins` | object | `top`, `right`, `bottom`, `left`; numbers or suffixed strings |
| `grid` | object | `cellWidth`/`cellHeight` in points, or `columns`/`rows` resolved against the content box |
| `footerReserve` | number | Optional; overrides the computed page-footer height for content boxes |

### 4.2 `fonts` and `styles`

- `fonts.<name>` declares `family` (string or ordered fallback array) and
  a default `size`. It does not embed anything; embedding is an exporter
  concern.
- `styles.<name>` declares typography and formatting: `font`, `size`,
  `bold`, `italic`, `underline`, `colour` (`#rgb` or `#rrggbb`),
  `align` (`left` \| `center` \| `right`), `valign`
  (`top` \| `middle` \| `bottom`), `lineSpacing`, `padding`, `border`
  (`{ width, colour }`), `fill`, `overflow` (`grow` \| `clip` \|
  `ellipsis`), and `format`.
- `format` supports `type`: `text`, `number` (`decimals`, `grouping`,
  `prefix`, `suffix`), `date` (`pattern` with `yyyy`, `MM`, `dd`, `HH`,
  `mm`, `ss`), `boolean` (`trueText`, `falseText`). It is not a full ICU
  pattern engine, deliberately.

### 4.3 `parameters`

`{ "name", "type", "required", "default" }` where `type` is `string`,
`integer`, `decimal`, `boolean`, or `datetime`. Missing required
parameters fail the build with a diagnostic.

### 4.4 `dataSets`

| Property | Notes |
|----------|-------|
| `name` | Referenced by expressions and by `SetDataSource` in the host app |
| `kind` | `rows` (default) or `single` |
| `fields` | `name` and `type`; types are advisory and validated on bind |
| `aggregates` | `name`, `function` (`sum`, `count`, `min`, `max`, `avg`), optional `field` |

A `single` dataset has exactly one record. `Customer.Name` is valid
regardless of the current section.

Aggregates are declared with `name`, `function` (`sum`, `count`, `min`,
`max`, `avg`) and, for everything except `count`, a `field`. Scope is
determined by where the aggregate is declared:

- declared on a **dataset** → report scope, accumulates over the whole run;
- declared on a **group** → group scope, resets when the group key changes.

**Aggregate names are unique across the document** and are referenced bare
in expressions: `{NetTotal}`, not `{Items.NetTotal}`. Uniqueness is what
removes the need for scope syntax, including when groups are nested. A
duplicate name is a validation error, and the fixtures enforce it.

The engine does not populate datasets. The host application calls
`SetDataSource("Items", list)`; a dataset declared in the template but
never supplied is an error.

### 4.5 `groups`

```json
"groups": [
  {
    "id": "by-customer",
    "dataSet": "Items",
    "key": "{CustomerCode}",
    "sort": [{ "field": "CustomerCode", "direction": "ascending" }],
    "repeatHeader": true,
    "aggregates": [
      { "name": "CustomerTotal", "function": "sum", "field": "Amount" }
    ]
  }
]
```

Groups are declared once and referenced by section `group` properties in
v0.2. The declaration order defines nesting, outermost first.
`repeatHeader` re-emits the group header after a page break inside the
group. Aggregates declared on a group reset when its key changes; their
names are document-unique like every other aggregate.

### 4.6 `sections`

| Property | Notes |
|----------|-------|
| `type` | `ReportHeader`, `PageHeader`, `GroupHeader`, `Detail`, `GroupFooter`, `PageFooter`, `ReportFooter` |
| `id` | Stable identifier |
| `height` | Minimum height in points; PageHeader/PageFooter are exact |
| `dataSet` | Binds detail repetition to a dataset |
| `group` | Group id, for group sections |
| `elements` | Ordered array; document order is paint order |
| `keepTogether` | Boolean, default `false` |
| `pageBreak` | `before` \| `after`, optional |
| `visible` | Expression, optional |

Section order in the array is irrelevant; the engine orders by type, with
groups resolved by declaration order. This keeps hand-edited files stable.

### 4.7 Elements

All elements share `id`, `bounds` **or** `cell`, `style`, `visible`, and
`z` (optional integer; document order wins on ties).

| Type | Additional properties |
|------|----------------------|
| `text` | `text` (static) |
| `field` | `value` (expression), `format` override |
| `image` | `resource`, `fit` (`contain` \| `stretch` \| `none`), `dpi` for `none` |
| `line` | `width`, `colour`, `dash` |
| `rect` | `width`, `colour`, `fill`, `radius` |

`text` and `field` are separate types on purpose: a static label has no
binding, and a field must not silently render its expression string when
a dataset is missing.

### 4.8 Expressions

Braced expressions are the only dynamic construct:

```text
{param.InvoiceNumber}
{Customer.Name}
{Description}                 resolves against the current section's dataset
{Quantity} * {UnitPrice}
{if({Amount} > 1000, "Review", "")}
{NetTotal}                    aggregate reference, document-unique name
{page.number} {page.count}
```

Text outside braces is literal and is not evaluated. Resolution order for
a bare name inside braces: aggregate, then section dataset field, then
parameters, then functions. A dotted name is `Dataset.Field` or
`Dataset.Aggregate`. Ambiguity is an error, not a guess.

Operators: `+ - * /`, comparison, `and or not`, `&` for concatenation,
parentheses, and `if(cond, a, b)`. Functions for 1.0: `len`, `upper`,
`lower`, `trim`, `round`, `abs`, `min`, `max`, `formatDate`. The grammar
is documented and unit-tested in M6; this section is the contract, not the
implementation.

## 5. Validation rules

1. Every element id is unique across the document.
2. Every `style`, `font`, `dataSet`, `group`, and aggregate referenced
   exists.
3. Section types required by the layout exist or are absent entirely;
   missing PageHeader is legal, two PageHeaders are not.
4. A `Detail` section declares a `dataSet`; other sections may not repeat.
5. PageHeader and PageFooter do not use `overflow: grow`.
6. Resources resolve inside the template directory.
7. No expression may reference a field not declared by its dataset.
8. Aggregate names are unique across the document, and each aggregate's
   `field` exists in the dataset it aggregates.
9. Exactly one of `bounds` or `cell` is present on each element, and a
   `cell` must fit within the declared grid columns.
10. Sections that are neither `Detail` nor group sections have no
    `dataSet` property.

Diagnostics carry the element id or JSON pointer, so a designer can
highlight the problem. The M0 fixture checker enforces rules 1-9; rule 10
is enforced with the engine.

## 6. Versioning and migration

- `schemaVersion` is `major.minor`.
- Minor additions may include new optional properties. Older engines warn
  and ignore them.
- Unknown element or section types are a hard error: silently dropping a
  report element is worse than refusing to render.
- A major bump requires a migration function from the previous major
  version, checked into the repository and covered by fixtures.
- The meaning of an existing property never changes without a major bump.

## 7. Security

- Templates are data. Nothing in a template executes code, opens a
  database, reads an arbitrary path, or fetches a URL.
- Resource references are relative; absolute paths and `..` escapes are
  rejected.
- Expression evaluation is bounded in depth and time.
- Datasets are supplied by the application, so a report cannot widen its
  own data access.

## 8. Open questions

These are settled with fixtures during M0/M1, not by discussion:

1. Does the invoice fixture need a `Detail` variant (for example, a
   sub-line for discounts) before 1.0?
2. Is `cell` positioning actually used by the designer, or should the
   schema store points and let the editor snap? Both are supported now;
   one may be removed.
3. Do any fixtures need a page-scope aggregate (for example, a page
   subtotal)? Report and group scope are already specified; page scope is
   not, and no fixture requires it yet.
4. Does the listing fixture require repeating the last detail line's
   description on continuation pages?

Answered during M0: aggregates are document-unique and referenced bare,
and groups may declare their own aggregates. This removed the need for
scope syntax in expressions and is reflected in
`fixtures/statement-grouped`.

Answers go into ADRs. Do not extend this schema otherwise.
