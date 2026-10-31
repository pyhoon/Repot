B4J=true
Group=Tests
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Engine unit tests for M1: units, loading, validation, round-trip, binding.
'They use the fixture set as real input so schema and code cannot drift.

Sub Class_Globals
	Public Checks As Int
	Public Failures As List
	Private mFixtures As String
End Sub

Public Sub Initialize
	Checks = 0
	Failures.Initialize
End Sub

Public Sub Run (FixturesDir As String)
	mFixtures = FixturesDir
	TestUnits
	TestFixturesLoadAndRoundTrip
	TestValidationFailures
	TestExpressionScanner
	TestDataBinder
End Sub

'--------------------------------------------------------------- units

Private Sub TestUnits
	CheckNear(72, RepotUnits.Millimetres(25.4), 0.0001, "25.4mm is 72pt")
	CheckNear(72, RepotUnits.Centimetres(2.54), 0.0001, "2.54cm is 72pt")
	CheckNear(72, RepotUnits.Inches(1), 0.0001, "1in is 72pt")
	CheckNear(34.0157, RepotUnits.ParseLength("12mm", 0), 0.001, "12mm parses to points")
	CheckNear(72, RepotUnits.ParseLength("1in", 0), 0.001, "1in parses to points")
	CheckNear(72, RepotUnits.ParseLength("96px", 96), 0.001, "96px at 96dpi is 72pt")
	CheckNear(10, RepotUnits.ParseLength(10, 0), 0.001, "plain number is points")

	Dim px As Double = RepotUnits.ParseLength("96px", 0)
	Check(RepotUnits.LastUnitError.Length > 0, "pixels without dpi are rejected")
	Dim bad As Double = RepotUnits.ParseLength("12qq", 0)
	Check(RepotUnits.LastUnitError.Length > 0, "unknown unit is rejected")
	Dim bad2 As Double = RepotUnits.ParseLength("abc", 0)
	Check(RepotUnits.LastUnitError.Length > 0, "non-numeric length is rejected")

	CheckText("595.2756", RepotUnits.FormatNumber(595.2755905511812, 4), "format rounds to 4 decimals")
	CheckText("-1.50", RepotUnits.FormatNumber(-1.5, 2), "negative formatting")
	CheckText("0.00", RepotUnits.FormatNumber(0, 2), "zero formatting")
	CheckText("10", RepotUnits.FormatNumber(10, 0), "integer formatting")
	CheckText("1.20", RepotUnits.FormatNumber(1.2, 2), "trailing zero formatting")
	CheckText("34.0157", RepotUnits.FormatNumber(RepotUnits.ParseLength("12mm", 0), 4), "12mm formatted")
End Sub

'--------------------------------------------------------------- fixtures

Private Sub TestFixturesLoadAndRoundTrip
	Dim names() As String = Array As String("invoice-basic", "listing-multipage", "statement-grouped")
	For Each name As String In names
		Dim dir As String = File.Combine(mFixtures, name)
		Dim loader As RepotTemplateLoader
		loader.Initialize
		Dim def As RepotDefinition = loader.LoadFromFile(dir, "template.b4xr")
		Check(loader.Diagnostics.HasErrors = False, name & " loads without errors: " & FirstErrors(loader.Diagnostics, 3))
		Check(loader.Diagnostics.WarningCount = 0, name & " loads without warnings: " & FirstWarnings(loader.Diagnostics, 3))
		Check(def.Sections.Size > 0, name & " has sections")
		Check(def.SectionByType("Detail") <> Null, name & " has a Detail section")
		Check(def.SectionByType("PageFooter") <> Null, name & " has a PageFooter")
		CheckNear(595.2756, def.Page.Width, 0.01, name & " page width is A4")
		CheckNear(841.8898, def.Page.Height, 0.01, name & " page height is A4")
		CheckNear(42.5197, def.Page.MarginLeft, 0.01, name & " left margin is 15mm")
		CheckNear(51.0236, def.Page.MarginBottom, 0.01, name & " bottom margin is 18mm")
		Check(def.Page.ContentWidth > 400, name & " has a usable content width")

		Dim detail As RepotSection = def.SectionByType("Detail")
		Check(detail.DataSet.Length > 0, name & " Detail declares a dataset")
		Check(def.DataSetByName(detail.DataSet) <> Null, name & " Detail dataset exists")

		'Canonical save, reload, save again: the two saves must be identical.
		Dim writer As RepotJsonWriter
		writer.Initialize
		Dim json1 As String = writer.ToJson(def)
		Dim loader2 As RepotTemplateLoader
		loader2.Initialize
		Dim def2 As RepotDefinition = loader2.LoadFromString(json1, dir)
		Check(loader2.Diagnostics.HasErrors = False, name & " reloads its own output: " & FirstErrors(loader2.Diagnostics, 3))
		Dim json2 As String = writer.ToJson(def2)
		CheckText(json1, json2, name & " round-trips through canonical JSON")

		'Loading the same input twice must produce the same canonical output.
		Dim loader3 As RepotTemplateLoader
		loader3.Initialize
		Dim def3 As RepotDefinition = loader3.LoadFromFile(dir, "template.b4xr")
		Dim json3 As String = writer.ToJson(def3)
		CheckText(json1, json3, name & " is deterministic across loads")
	Next
End Sub

'--------------------------------------------------------------- validation

Private Sub TestValidationFailures
	Dim dir As String = File.Combine(mFixtures, "invoice-basic")
	Dim good As String = File.ReadString(dir, "template.b4xr")
	Dim q As String = Chr(34)

	'Unknown style reference.
	Dim bad As String = good.Replace(q & "style" & q & ": " & q & "label" & q, q & "style" & q & ": " & q & "nope" & q)
	ExpectError("unknown style", bad, dir, "E-VAL-096")

	'Three-number bounds.
	bad = good.Replace(q & "bounds" & q & ": [0, 0, 240, 14]", q & "bounds" & q & ": [0, 0, 240]")
	ExpectError("malformed bounds", bad, dir, "E-TPL-112")

	'Duplicate aggregate name.
	bad = good.Replace(q & "name" & q & ": " & q & "LineCount" & q, q & "name" & q & ": " & q & "NetTotal" & q)
	ExpectError("duplicate aggregate", bad, dir, "E-VAL-050")

	'Unknown field in an expression.
	bad = good.Replace(q & "value" & q & ": " & q & "{Description}" & q, q & "value" & q & ": " & q & "{Nope}" & q)
	ExpectError("unknown expression field", bad, dir, "E-EXPR-013")

	'Detail references a missing dataset.
	bad = good.Replace(q & "dataSet" & q & ": " & q & "Items" & q, q & "dataSet" & q & ": " & q & "Missing" & q)
	ExpectError("missing detail dataset", bad, dir, "E-VAL-081")

	'Unknown section type.
	bad = good.Replace(q & "type" & q & ": " & q & "Detail" & q, q & "type" & q & ": " & q & "Nope" & q)
	ExpectError("unknown section type", bad, dir, "E-VAL-072")

	'Unbalanced expression.
	bad = good.Replace(q & "{Description}" & q, q & "{Description" & q)
	ExpectError("unbalanced expression", bad, dir, "E-EXPR-002")

	'Parameter referenced but not declared.
	bad = good.Replace(q & "{param.InvoiceNumber}" & q, q & "{param.Unknown}" & q)
	ExpectError("unknown parameter", bad, dir, "E-EXPR-010")
End Sub

Private Sub ExpectError (Label As String, TemplateText As String, BaseDir As String, Code As String)
	Dim loader As RepotTemplateLoader
	loader.Initialize
	Dim def As RepotDefinition = loader.LoadFromString(TemplateText, BaseDir)
	Check(loader.Diagnostics.HasErrors, Label & " is rejected")
	CheckError(loader.Diagnostics, Code, Label & " reports " & Code)
End Sub

'--------------------------------------------------------------- expressions

Private Sub TestExpressionScanner
	Dim diags As RepotDiagnostics
	diags.Initialize
	Dim exprs As List = RepotExpressionRefs.Extract("Page {page.number} of {page.count}", diags, "/test")
	Check(diags.HasErrors = False, "page expressions extract cleanly")
	Check(exprs.Size = 2, "two expressions extract")
	CheckText("page.number", exprs.Get(0), "first expression content")

	Dim nested As List = RepotExpressionRefs.Extract("{if({Amount} > 1000, ""Review"", """")}", diags, "/test")
	Check(diags.HasErrors = False, "nested braces extract cleanly")
	Check(nested.Size = 1, "nested expression is one expression")
	Dim ids As List = RepotExpressionRefs.Identifiers(nested.Get(0), diags, "/test")
	Check(ids.IndexOf("if") >= 0, "nested expression keeps function identifier")
	Check(ids.IndexOf("Amount") >= 0, "nested expression keeps field identifier")
	Check(ids.IndexOf("Review") < 0, "string literal is not an identifier")

	diags.Initialize
	Dim bad As List = RepotExpressionRefs.Extract("Page {page.number", diags, "/test")
	Check(diags.HasErrors, "unbalanced brace is rejected")

	diags.Initialize
	Dim bad2 As List = RepotExpressionRefs.Extract("{}", diags, "/test")
	Check(diags.HasErrors, "empty expression is rejected")

	diags.Initialize
	Dim ids2 As List = RepotExpressionRefs.Identifiers("if({Amount} > 1, ""x"", """")", diags, "/test")
	Check(diags.HasErrors = False, "nested identifiers scan cleanly")

	Dim escaped As String = RepotJsonUtil.JsonQuote("a" & Chr(34) & "b" & Chr(10) & Chr(92) & "c")
	Check(escaped.IndexOf(Chr(92) & Chr(34)) >= 0, "quote escaping")
	Check(escaped.IndexOf(Chr(92) & "n") >= 0, "newline escaping")
	Check(escaped.IndexOf(Chr(92) & Chr(92)) >= 0, "backslash escaping")
End Sub

'--------------------------------------------------------------- binding

Private Sub TestDataBinder
	Dim dir As String = File.Combine(mFixtures, "invoice-basic")
	Dim loader As RepotTemplateLoader
	loader.Initialize
	Dim def As RepotDefinition = loader.LoadFromFile(dir, "template.b4xr")
	Check(loader.Diagnostics.HasErrors = False, "invoice loads for binding")

	Dim binder As RepotDataBinder
	binder.Initialize(def)
	Dim data As Map = LoadJsonMap(dir, "data.json")
	BindData(binder, def, data)
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Check(binder.Validate, "invoice binds with fixture data: " & FirstErrors(binder.Diagnostics, 3))
	Dim items As RepotDataSet = binder.GetDataSet("Items")
	Check(items <> Null, "bound Items dataset exists")
	Check(items.Count = 4, "bound Items has four records")
	Dim customer As RepotDataSet = binder.GetDataSet("Customer")
	Check(customer.Count = 1, "bound single Customer has one record")
	CheckText("Northwind Traders", customer.RecordAt(0).Get("Name"), "bound string value")

	'Missing required parameter.
	Dim b2 As RepotDataBinder
	b2.Initialize(def)
	BindData(b2, def, data)
	Check(b2.Validate = False, "missing required parameter fails validation")
	CheckError(b2.Diagnostics, "E-DATA-011", "missing parameter reports E-DATA-011")

	'Missing dataset.
	Dim b3 As RepotDataBinder
	b3.Initialize(def)
	b3.SetParameter("InvoiceNumber", "INV-1")
	b3.SetParameter("IssuedOn", "2026-01-01")
	Check(b3.Validate = False, "missing dataset fails validation")
	CheckError(b3.Diagnostics, "E-DATA-010", "missing dataset reports E-DATA-010")

	'Wrong dataset shape.
	Dim b4 As RepotDataBinder
	b4.Initialize(def)
	Dim emptyRecord As Map
	emptyRecord.Initialize
	b4.SetDataSourceSingle("Items", emptyRecord)
	CheckError(b4.Diagnostics, "E-DATA-004", "single on a rows dataset reports E-DATA-004")

	'Wrong value type.
	Dim b5 As RepotDataBinder
	b5.Initialize(def)
	Dim rows As List
	rows.Initialize
	Dim row As Map
	row.Initialize
	row.Put("Description", 123)
	row.Put("Quantity", 1)
	row.Put("UnitPrice", 1)
	row.Put("Amount", 1)
	rows.Add(row)
	b5.SetDataSource("Items", rows)
	CheckError(b5.Diagnostics, "E-DATA-020", "wrong field type reports E-DATA-020")

	'Unknown field is a warning, not an error.
	Dim b6 As RepotDataBinder
	b6.Initialize(def)
	Dim rows2 As List
	rows2.Initialize
	Dim row2 As Map
	row2.Initialize
	row2.Put("Description", "x")
	row2.Put("Quantity", 1)
	row2.Put("UnitPrice", 1)
	row2.Put("Amount", 1)
	row2.Put("Extra", "ignored")
	rows2.Add(row2)
	b6.SetDataSource("Items", rows2)
	Check(b6.Diagnostics.WarningCount = 1, "unknown field warns")
	Check(b6.Diagnostics.ErrorCount = 0, "unknown field is not an error")

	'Parameters with an explicit default bind without being set.
	Dim q As String = Chr(34)
	Dim target As String = q & "name" & q & ": " & q & "InvoiceNumber" & q & ", " & q & "type" & q & ": " & q & "string" & q & ", " & q & "required" & q & ": true"
	Dim replacement As String = target & ", " & q & "default" & q & ": " & q & "INV-0" & q
	Dim withDefault As String = File.ReadString(dir, "template.b4xr").Replace(target, replacement)
	Dim loaderD As RepotTemplateLoader
	loaderD.Initialize
	Dim defD As RepotDefinition = loaderD.LoadFromString(withDefault, dir)
	Check(loaderD.Diagnostics.HasErrors = False, "template with parameter default loads")
	Dim b7 As RepotDataBinder
	b7.Initialize(defD)
	Check(b7.Parameters.ContainsKey("InvoiceNumber"), "parameter default is applied")
	CheckText("INV-0", b7.Parameters.Get("InvoiceNumber"), "parameter default value")
End Sub

Private Sub BindData (Binder As RepotDataBinder, Def As RepotDefinition, Data As Map)
	For Each name As String In Data.Keys
		Dim dsDef As RepotDataSetDef = Def.DataSetByName(name)
		If dsDef = Null Then Continue
		If dsDef.Kind = "single" Then
			Binder.SetDataSourceSingle(name, Data.Get(name))
		Else
			Binder.SetDataSource(name, Data.Get(name))
		End If
	Next
End Sub

'--------------------------------------------------------------- helpers

Private Sub Check (Ok As Boolean, Message As String)
	Checks = Checks + 1
	If Ok = False Then Failures.Add(Message)
End Sub

Private Sub CheckText (Expected As String, Actual As String, Message As String)
	Checks = Checks + 1
	If Expected <> Actual Then
		Failures.Add(Message & " (expected [" & Expected & "], actual [" & Actual & "])")
	End If
End Sub

Private Sub CheckNear (Expected As Double, Actual As Double, Tolerance As Double, Message As String)
	Checks = Checks + 1
	If Abs(Expected - Actual) > Tolerance Then
		Failures.Add(Message & " (expected " & Expected & ", actual " & Actual & ")")
	End If
End Sub

Private Sub CheckError (Diags As RepotDiagnostics, Code As String, Message As String)
	Dim found As Boolean = False
	For Each d As RepotDiagnostic In Diags.Items
		If d.Code = Code Then found = True
	Next
	Check(found, Message & " (diagnostic not found)")
End Sub

Private Sub FirstWarnings (Diags As RepotDiagnostics, Limit As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim n As Int = 0
	For Each d As RepotDiagnostic In Diags.Items
		If d.Severity = "warning" Then
			If n > 0 Then sb.Append("; ")
			sb.Append(d.Code).Append(" ").Append(d.Message)
			n = n + 1
			If n >= Limit Then Exit
		End If
	Next
	Return sb.ToString
End Sub

Private Sub FirstErrors (Diags As RepotDiagnostics, Limit As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim n As Int = 0
	For Each d As RepotDiagnostic In Diags.Items
		If d.Severity = "error" Then
			If n > 0 Then sb.Append("; ")
			sb.Append(d.Code).Append(" ").Append(d.Message)
			n = n + 1
			If n >= Limit Then Exit
		End If
	Next
	Return sb.ToString
End Sub

Private Sub LoadJsonMap (Dir As String, Name As String) As Map
	Dim txt As String = File.ReadString(Dir, Name)
	Dim parser As JSONParser
	parser.Initialize(txt)
	Dim m As Map = parser.NextObject
	Return m
End Sub
