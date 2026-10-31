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
	TestRenderDocument
	TestMeasurement
	TestBandLayout
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

'--------------------------------------------------------------- render document

Private Sub TestRenderDocument
	CheckNear(1.23, RepotUnits.RoundTo(1.234, 2), 0.0001, "round down to 0.01 pt")
	CheckNear(1.24, RepotUnits.RoundTo(1.236, 2), 0.0001, "round up to 0.01 pt")
	CheckNear(-1.24, RepotUnits.RoundTo(-1.236, 2), 0.0001, "negative rounds away from zero")
	CheckNear(10, RepotUnits.RoundTo(10, 2), 0.0001, "whole number is unchanged")

	Dim doc As RepotRenderDocument
	doc.Initialize
	Check(doc.Version = 1, "render document version is 1")
	Check(doc.PageCount = 0, "new render document has no pages")
	Check(doc.PageAt(1) = Null, "page lookup rejects index zero")

	Dim p As RepotRenderPage = doc.AddPage(595.2755905511812, 841.8897637795277)
	Check(doc.PageCount = 1, "page is added")
	Check(p.Index = 1, "first page index is 1")
	CheckNear(595.2756, p.Width, 0.0001, "page width is kept at full precision")
	CheckNear(841.8898, p.Height, 0.0001, "page height is kept at full precision")
	Check(doc.PageAt(1).Index = 1, "page lookup is 1-based")
	Check(doc.PageAt(2) = Null, "page lookup rejects an out-of-range index")

	Dim p2 As RepotRenderPage = doc.AddPage(612, 792)
	Check(p2.Index = 2, "second page index is 2")
	Check(doc.PageAt(2).Index = 2, "second page is found")

	Dim t As RepotDrawOp = p.AddText(10.004, 20.006, 100.004, 12.006, 9.004, "Hello", "DejaVu Sans", 9, False, False, True, "#112233", "right")
	CheckText("text", t.OpType, "text operation type")
	CheckNear(10, t.X, 0.0001, "text x is rounded")
	CheckNear(20.01, t.Y, 0.0001, "text y is rounded")
	CheckNear(100, t.Width, 0.0001, "text width is rounded")
	CheckNear(12.01, t.Height, 0.0001, "text height is rounded")
	CheckNear(9, t.Baseline, 0.0001, "text baseline is rounded")
	CheckText("Hello", t.Text, "text content")
	CheckText("DejaVu Sans", t.FontName, "text font family")
	Check(t.Underline, "text underline flag")
	CheckText("#112233", t.Colour, "text colour")
	CheckText("right", t.Align, "text alignment")

	Dim aligned As RepotDrawOp = p.AddText(0, 0, 10, 10, 8, "x", "f", 9, False, False, False, "", "")
	CheckText("left", aligned.Align, "empty alignment defaults to left")

	Dim img As RepotDrawOp = p.AddImage(0, 0, 130, 48, "logo.png", 200, 100, 0, "", Null)
	CheckText("image", img.OpType, "image operation type")
	CheckText("logo.png", img.ResourcePath, "image resource path")
	Check(img.PixelWidth = 200 And img.PixelHeight = 100, "image intrinsic size")
	CheckText("contain", img.Fit, "empty image fit defaults to contain")
	Check(img.Handle = Null, "image handle can be null")

	Dim ln As RepotDrawOp = p.AddLine(0, 17, 510, 17, 0.5, "#999999", "")
	CheckText("line", ln.OpType, "line operation type")
	CheckNear(510, ln.X2, 0.0001, "line end x")
	CheckNear(17, ln.Y2, 0.0001, "line end y")
	CheckText("#999999", ln.Colour, "line colour")

	Dim rc As RepotDrawOp = p.AddRect(1.006, 2.006, 3.006, 4.006, 0.5, "#000000", "#ffffff", 2.004)
	CheckText("rect", rc.OpType, "rect operation type")
	CheckNear(1.01, rc.X, 0.0001, "rect x is rounded")
	CheckNear(4.01, rc.Height, 0.0001, "rect height is rounded")
	CheckText("#ffffff", rc.FillColour, "rect fill colour")
	CheckNear(2, rc.Radius, 0.0001, "rect radius is rounded")

	Dim cl As RepotDrawOp = p.AddClip(0, 0, 100, 50)
	CheckText("clip", cl.OpType, "clip operation type")
	Dim rs As RepotDrawOp = p.AddRestore
	CheckText("restore", rs.OpType, "restore operation type")

	Dim lk As RepotDrawOp = p.AddLink(0, 0, 100, 12, "https://example.com", "")
	CheckText("link", lk.OpType, "link operation type")
	CheckText("https://example.com", lk.Url, "external link url")
	Dim lk2 As RepotDrawOp = p.AddLink(0, 0, 100, 12, "", "chapter-1")
	CheckText("chapter-1", lk2.AnchorName, "internal link anchor")

	Dim a As RepotRenderAnchor = p.AddAnchor("chapter-1", 5.006, 6.004)
	CheckText("chapter-1", a.Name, "anchor name")
	CheckNear(5.01, a.X, 0.0001, "anchor x is rounded")
	CheckNear(6, a.Y, 0.0001, "anchor y is rounded")
	Check(p.Anchors.Size = 1, "one anchor is stored")

	Check(p.Ops.Size = 9, "page operations keep insertion order and count")
	Dim first As RepotDrawOp = p.Ops.Get(0)
	Dim last As RepotDrawOp = p.Ops.Get(p.Ops.Size - 1)
	CheckText("text", first.OpType, "first operation is the text run")
	CheckText("link", last.OpType, "last operation is the second link")
End Sub

'--------------------------------------------------------------- measurement

Private Sub TestMeasurement
	Dim diags As RepotDiagnostics
	diags.Initialize
	Dim mm As RepotB4JMeasure
	mm.Initialize(diags)
	Check(mm.IsAvailable, "measurement adapter is available headless")

	Dim body As RepotTextStyle
	body.Initialize
	body.SetFamily("Arial")
	body.Size = 12

	Dim f As RepotFont = mm.ResolveStyle(body)
	CheckText("Arial", f.Family, "declared family is resolved as-is")
	CheckText("Arial", f.RequestedFamily, "requested family is recorded")
	Check(f.Substituted = False, "available family is not substituted")
	Check(f.HasMetrics, "resolved font has vertical metrics")
	Check(f.Ascent > 0, "ascent is positive")
	Check(f.Descent > 0, "descent is positive")
	CheckNear(12, f.Size, 0.0001, "font size is retained")

	Dim w12 As Double = mm.MeasureLine("Hello", body)
	Check(w12 > 0, "line width is measured, not guessed")
	CheckNear(w12, mm.MeasureLine("Hello", body), 0.000001, "repeated measurement is identical")
	Check(mm.MeasureLine("Hello, world", body) > w12, "longer text is wider")
	CheckNear(0, mm.MeasureLine("", body), 0.000001, "empty line has zero width")
	CheckNear(0, mm.MeasureLine("   ", body), 0.000001, "whitespace-only text has zero width")

	Dim large As RepotTextStyle = body.Copy
	large.Size = 24
	CheckNear(w12 * 2, mm.MeasureLine("Hello", large), 0.05, "advance scales with point size")
	Dim f24 As RepotFont = mm.ResolveStyle(large)
	CheckNear(f.Ascent * 2, f24.Ascent, 0.05, "ascent scales with point size")
	CheckNear(f.Descent * 2, f24.Descent, 0.05, "descent scales with point size")

	Dim fractional As RepotTextStyle = body.Copy
	fractional.Size = 10.5
	CheckNear(w12 * 10.5 / 12, mm.MeasureLine("Hello", fractional), 0.05, "fractional point size scales linearly")

	Dim bold As RepotTextStyle = body.Copy
	bold.Bold = True
	Check(mm.MeasureLine("Hello", bold) > w12, "bold face is measured with bold metrics")

	CheckNear(14.4, mm.LineHeight(body), 0.0001, "line height is size times line spacing")
	Dim tight As RepotTextStyle = body.Copy
	tight.LineSpacing = 1
	CheckNear(12, mm.LineHeight(tight), 0.0001, "line spacing one gives the font size")

	Dim one As RepotTextMetrics = mm.MeasureBlock("Hello world", body, 1000)
	Check(one.LineCount = 1, "wide block stays on one line")
	CheckText("Hello world", one.Lines.Get(0), "single line keeps its text")
	CheckNear(mm.MeasureLine("Hello world", body), one.Width, 0.0001, "block width matches line measurement")
	CheckNear(one.LineHeight, one.Height, 0.0001, "one-line block height is one line height")
	CheckNear(f.Ascent, one.Ascent, 0.0001, "block ascent comes from the font")

	Dim narrow As RepotTextMetrics = mm.MeasureBlock("Hello world", body, 40)
	Check(narrow.LineCount = 2, "narrow block wraps at the space")
	CheckText("Hello", narrow.Lines.Get(0), "first wrapped line")
	CheckText("world", narrow.Lines.Get(1), "second wrapped line")
	Check(narrow.Width <= 40.0001, "wrapped lines fit the maximum width")
	CheckNear(narrow.LineHeight * 2, narrow.Height, 0.0001, "two-line block height is two line heights")

	Dim explicit As RepotTextMetrics = mm.MeasureBlock("Hello" & Chr(10) & "world", body, 1000)
	Check(explicit.LineCount = 2, "explicit line break is honoured")
	CheckText("world", explicit.Lines.Get(1), "text after the explicit break")

	Dim trailing As RepotTextMetrics = mm.MeasureBlock("Hello   ", body, 1000)
	CheckText("Hello", trailing.Lines.Get(0), "trailing whitespace is removed")
	CheckNear(w12, trailing.Width, 0.0001, "trailing whitespace does not affect width")

	Dim longWord As RepotTextMetrics = mm.MeasureBlock("Supercalifragilistic", body, 30)
	Check(longWord.LineCount > 1, "over-wide word is broken by character")
	Dim fit As Boolean = True
	For Each lw As Double In longWord.Widths
		If lw > 30.0001 Then fit = False
	Next
	Check(fit, "character-broken lines fit the maximum width")

	Dim empty As RepotTextMetrics = mm.MeasureBlock("", body, 100)
	Check(empty.LineCount = 1, "empty block has one empty line")
	CheckText("", empty.Lines.Get(0), "empty block line is empty")
	CheckNear(0, empty.Width, 0.000001, "empty block has zero width")
	CheckNear(empty.LineHeight, empty.Height, 0.0001, "empty block still has a line height")

	Dim noWrap As RepotTextMetrics = mm.MeasureBlock("Hello world", body, 0)
	Check(noWrap.LineCount = 1, "zero maximum width disables wrapping")

	Dim fb As RepotTextStyle
	fb.Initialize
	fb.SetFamily("NoSuchFamilyXYZ")
	fb.Size = 12
	Dim before As Int = diags.WarningCount
	Dim fallback As RepotFont = mm.ResolveStyle(fb)
	CheckText("Dialog", fallback.Family, "missing family falls back to the platform default")
	Check(fallback.Substituted, "platform default is reported as a substitution")
	Check(diags.WarningCount > before, "substitution records a warning")
	Check(HasDiagnostic(diags, "W-MEA-001"), "substitution warning has a stable code")

	Dim declared As RepotTextStyle
	declared.Initialize
	declared.Family.Add("NoSuchFamilyXYZ")
	declared.Family.Add("Arial")
	declared.Size = 12
	Dim second As RepotFont = mm.ResolveStyle(declared)
	CheckText("Arial", second.Family, "declared fallback order is followed")
	Check(second.Substituted, "using a later declared family is reported")
	CheckText("NoSuchFamilyXYZ", second.RequestedFamily, "primary requested family is retained")

	Dim logical As RepotTextStyle
	logical.Initialize
	logical.SetFamily("sans-serif")
	logical.Size = 12
	Dim logicalFont As RepotFont = mm.ResolveStyle(logical)
	Check(logicalFont.Substituted = False, "logical family is not a substitution")
	Check(logicalFont.HasMetrics, "logical family has metrics")
End Sub

'--------------------------------------------------------------- band layout

Private Sub TestBandLayout
	Dim def As RepotDefinition = MakeBandDefinition
	Dim sec As RepotSection = def.Sections.Get(0)
	Dim measure As RepotB4JMeasure
	Dim diags As RepotDiagnostics
	diags.Initialize
	measure.Initialize(diags)
	Dim layout As RepotBandLayout
	layout.Initialize(diags, measure)

	Dim band As RepotBand = layout.LayoutBand(def, sec, def.Page.ContentWidth, def.Page.ContentHeight, Null)
	Check(band.Width = def.Page.ContentWidth, "band uses the content width")
	Check(band.Elements.Size = 2, "band keeps its children")

	Dim title As RepotLayoutElement = band.Elements.Get(0)
	Dim note As RepotLayoutElement = band.Elements.Get(1)
	CheckNear(0, title.X, 0.0001, "first child keeps its x")
	CheckNear(0, title.Y, 0.0001, "first child keeps its y")
	CheckNear(40, title.Width, 0.0001, "declared width is retained")
	Check(title.Style.Family.Get(0) = "Arial", "style resolves the declared font family")
	Check(title.Font.Family = "Arial", "measurement resolves the font")
	Check(title.Align = "left", "element inherits style alignment")
	Check(title.Overflow = "grow", "element inherits style overflow")

	Check(title.Lines.Size = 2, "wide text wraps to two lines")
	Check(title.Height > title.DeclaredHeight, "growing element increases its height")
	Check(note.Y >= title.Y + title.DeclaredHeight - 0.0001, "push-down moves the later child")
	Check(note.Y = title.Y + title.DeclaredHeight + title.GrowBy, "push-down uses the growth delta")
	Check(band.Height >= note.Y + note.Height, "band height covers the pushed child")

	' grid normalisation
	Dim gdef As RepotDefinition = MakeGridDefinition
	Dim gsec As RepotSection = gdef.Sections.Get(0)
	Dim gband As RepotBand = layout.LayoutBand(gdef, gsec, gdef.Page.ContentWidth, gdef.Page.ContentHeight, Null)
	Dim cell As RepotLayoutElement = gband.Elements.Get(0)
	CheckNear(10, cell.X, 0.0001, "grid cell x is col times cell width")
	CheckNear(10, cell.Y, 0.0001, "grid cell y is row times cell height")
	CheckNear(20, cell.Width, 0.0001, "grid cell width is colSpan times cell width")
	CheckNear(10, cell.Height, 0.0001, "grid cell height is rowSpan times cell height")

	' clip keeps the declared height
	Dim cdef As RepotDefinition = MakeBandDefinition
	Dim csec As RepotSection = cdef.Sections.Get(0)
	Dim clipEl As RepotElement = csec.Elements.Get(0)
	clipEl.Height = 12
	Dim cstyle As RepotStyle = cdef.Styles.Get("body")
	cstyle.Overflow = "clip"
	Dim cband As RepotBand = layout.LayoutBand(cdef, csec, cdef.Page.ContentWidth, cdef.Page.ContentHeight, Null)
	Dim citem As RepotLayoutElement = cband.Elements.Get(0)
	Check(citem.Height = 12, "clip does not grow the element")
	Check(citem.Lines.Size <= 1, "clip limits the laid-out lines")

	' min height
	Dim mdef As RepotDefinition = MakeBandDefinition
	Dim msec As RepotSection = mdef.Sections.Get(0)
	msec.Height = 100
	Dim mband As RepotBand = layout.LayoutBand(mdef, msec, mdef.Page.ContentWidth, mdef.Page.ContentHeight, Null)
	Check(mband.Height >= 100, "band never shrinks below its declared height")

	' element-level align override
	Dim adef As RepotDefinition = MakeBandDefinition
	Dim asec As RepotSection = adef.Sections.Get(0)
	Dim alignEl As RepotElement = asec.Elements.Get(0)
	alignEl.Align = "right"
	Dim aband As RepotBand = layout.LayoutBand(adef, asec, adef.Page.ContentWidth, adef.Page.ContentHeight, Null)
	Dim aitem As RepotLayoutElement = aband.Elements.Get(0)
	Check(aitem.Align = "right", "element align overrides the style")

	' field content comes from the values map
	Dim fdef As RepotDefinition = MakeBandDefinition
	Dim fsec As RepotSection = fdef.Sections.Get(0)
	Dim fieldEl As RepotElement = fsec.Elements.Get(1)
	fieldEl.ElementType = "field"
	fieldEl.ValueExpression = "{X}"
	Dim vals As Map
	vals.Initialize
	vals.Put(fieldEl.Id, "field text")
	Dim fband As RepotBand = layout.LayoutBand(fdef, fsec, fdef.Page.ContentWidth, fdef.Page.ContentHeight, vals)
	Dim fitem As RepotLayoutElement = fband.Elements.Get(1)
	Check(fitem.Content = "field text", "field content is taken from the values map")
End Sub

Private Sub MakeBandDefinition As RepotDefinition
	Dim def As RepotDefinition
	def.Initialize
	def.Page.Width = 200
	def.Page.Height = 300
	def.Page.MarginTop = 0
	def.Page.MarginRight = 0
	def.Page.MarginBottom = 0
	def.Page.MarginLeft = 0

	Dim fd As RepotFontDef
	fd.Initialize
	fd.Name = "body"
	fd.Family.Add("Arial")
	fd.Size = 12
	def.Fonts.Put("body", fd)

	Dim st As RepotStyle
	st.Initialize
	st.Name = "body"
	st.FontName = "body"
	st.Size = 12
	st.LineSpacing = 1.2
	st.Overflow = "grow"
	st.Align = "left"
	st.Valign = "top"
	def.Styles.Put("body", st)

	Dim sec As RepotSection
	sec.Initialize
	sec.SectionType = "Detail"
	sec.Id = "detail"
	sec.Height = 10

	Dim e1 As RepotElement
	e1.Initialize
	e1.ElementType = "text"
	e1.Id = "title"
	e1.X = 0
	e1.Y = 0
	e1.Width = 40
	e1.Height = 12
	e1.StyleName = "body"
	e1.Text = "Hello world"
	sec.Elements.Add(e1)

	Dim e2 As RepotElement
	e2.Initialize
	e2.ElementType = "text"
	e2.Id = "note"
	e2.X = 0
	e2.Y = 12
	e2.Width = 40
	e2.Height = 10
	e2.StyleName = "body"
	e2.Text = "note"
	sec.Elements.Add(e2)

	def.Sections.Add(sec)
	Return def
End Sub

Private Sub MakeGridDefinition As RepotDefinition
	Dim def As RepotDefinition
	def.Initialize
	def.Page.Width = 100
	def.Page.Height = 50
	def.Page.MarginTop = 0
	def.Page.MarginRight = 0
	def.Page.MarginBottom = 0
	def.Page.MarginLeft = 0
	def.Page.GridColumns = 10
	def.Page.GridRows = 5

	Dim fd As RepotFontDef
	fd.Initialize
	fd.Name = "body"
	fd.Family.Add("Arial")
	fd.Size = 12
	def.Fonts.Put("body", fd)

	Dim st As RepotStyle
	st.Initialize
	st.Name = "body"
	st.FontName = "body"
	st.Size = 12
	st.Overflow = "clip"
	def.Styles.Put("body", st)

	Dim sec As RepotSection
	sec.Initialize
	sec.SectionType = "Detail"
	sec.Id = "detail"
	sec.Height = 0

	Dim e As RepotElement
	e.Initialize
	e.ElementType = "text"
	e.Id = "cell"
	e.UseCell = True
	e.CellCol = 1
	e.CellRow = 1
	e.CellColSpan = 2
	e.CellRowSpan = 1
	e.StyleName = "body"
	e.Text = "x"
	sec.Elements.Add(e)

	def.Sections.Add(sec)
	Return def
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

Private Sub HasDiagnostic (Diags As RepotDiagnostics, Code As String) As Boolean
	For Each d As RepotDiagnostic In Diags.Items
		If d.Code = Code Then Return True
	Next
	Return False
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
