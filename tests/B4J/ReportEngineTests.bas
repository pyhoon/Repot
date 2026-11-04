B4A=false
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
	TestPagination
	TestGoldens
	TestPdfExport
	TestMultilangPdf
	TestRtlArabicPdf
	TestRtlHebrewPdf
	TestMixedScriptsPdf
	TestFacade
	TestHtmlExport
	TestDataExport
	TestOfficeExport
	TestExpressions
	TestGrouping
	TestFixturesLoadAndRoundTrip
	TestValidationFailures
	TestExpressionScanner
	TestDataBinder
End Sub

'--------------------------------------------------------------- units

Private Sub TestUnits
	CheckNear(72, ReportUnits.Millimetres(25.4), 0.0001, "25.4mm is 72pt")
	CheckNear(72, ReportUnits.Centimetres(2.54), 0.0001, "2.54cm is 72pt")
	CheckNear(72, ReportUnits.Inches(1), 0.0001, "1in is 72pt")
	CheckNear(34.0157, ReportUnits.ParseLength("12mm", 0), 0.001, "12mm parses to points")
	CheckNear(72, ReportUnits.ParseLength("1in", 0), 0.001, "1in parses to points")
	CheckNear(72, ReportUnits.ParseLength("96px", 96), 0.001, "96px at 96dpi is 72pt")
	CheckNear(10, ReportUnits.ParseLength(10, 0), 0.001, "plain number is points")

	Dim px As Double = ReportUnits.ParseLength("96px", 0)
	Check(ReportUnits.LastUnitError.Length > 0, "pixels without dpi are rejected")
	Dim bad As Double = ReportUnits.ParseLength("12qq", 0)
	Check(ReportUnits.LastUnitError.Length > 0, "unknown unit is rejected")
	Dim bad2 As Double = ReportUnits.ParseLength("abc", 0)
	Check(ReportUnits.LastUnitError.Length > 0, "non-numeric length is rejected")

	CheckText("595.2756", ReportUnits.FormatNumber(595.2755905511812, 4), "format rounds to 4 decimals")
	CheckText("-1.50", ReportUnits.FormatNumber(-1.5, 2), "negative formatting")
	CheckText("0.00", ReportUnits.FormatNumber(0, 2), "zero formatting")
	CheckText("10", ReportUnits.FormatNumber(10, 0), "integer formatting")
	CheckText("1.20", ReportUnits.FormatNumber(1.2, 2), "trailing zero formatting")
	CheckText("34.0157", ReportUnits.FormatNumber(ReportUnits.ParseLength("12mm", 0), 4), "12mm formatted")
End Sub

'--------------------------------------------------------------- render document

Private Sub TestRenderDocument
	CheckNear(1.23, ReportUnits.RoundTo(1.234, 2), 0.0001, "round down to 0.01 pt")
	CheckNear(1.24, ReportUnits.RoundTo(1.236, 2), 0.0001, "round up to 0.01 pt")
	CheckNear(-1.24, ReportUnits.RoundTo(-1.236, 2), 0.0001, "negative rounds away from zero")
	CheckNear(10, ReportUnits.RoundTo(10, 2), 0.0001, "whole number is unchanged")

	Dim doc As ReportRenderDocument
	doc.Initialize
	Check(doc.Version = 1, "render document version is 1")
	Check(doc.PageCount = 0, "new render document has no pages")
	Check(doc.PageAt(1) = Null, "page lookup rejects index zero")

	Dim p As ReportRenderPage = doc.AddPage(595.2755905511812, 841.8897637795277)
	Check(doc.PageCount = 1, "page is added")
	Check(p.Index = 1, "first page index is 1")
	CheckNear(595.2756, p.Width, 0.0001, "page width is kept at full precision")
	CheckNear(841.8898, p.Height, 0.0001, "page height is kept at full precision")
	Check(doc.PageAt(1).Index = 1, "page lookup is 1-based")
	Check(doc.PageAt(2) = Null, "page lookup rejects an out-of-range index")

	Dim p2 As ReportRenderPage = doc.AddPage(612, 792)
	Check(p2.Index = 2, "second page index is 2")
	Check(doc.PageAt(2).Index = 2, "second page is found")

	Dim t As ReportDrawOp = p.AddText(10.004, 20.006, 100.004, 12.006, 9.004, "Hello", "DejaVu Sans", 9, False, False, True, "#112233", "right")
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

	Dim aligned As ReportDrawOp = p.AddText(0, 0, 10, 10, 8, "x", "f", 9, False, False, False, "", "")
	CheckText("left", aligned.Align, "empty alignment defaults to left")

	Dim img As ReportDrawOp = p.AddImage(0, 0, 130, 48, "logo.png", 200, 100, 0, "", Null)
	CheckText("image", img.OpType, "image operation type")
	CheckText("logo.png", img.ResourcePath, "image resource path")
	Check(img.PixelWidth = 200 And img.PixelHeight = 100, "image intrinsic size")
	CheckText("contain", img.Fit, "empty image fit defaults to contain")
	Check(img.Handle = Null, "image handle can be null")

	Dim ln As ReportDrawOp = p.AddLine(0, 17, 510, 17, 0.5, "#999999", "")
	CheckText("line", ln.OpType, "line operation type")
	CheckNear(510, ln.X2, 0.0001, "line end x")
	CheckNear(17, ln.Y2, 0.0001, "line end y")
	CheckText("#999999", ln.Colour, "line colour")

	Dim rc As ReportDrawOp = p.AddRect(1.006, 2.006, 3.006, 4.006, 0.5, "#000000", "#ffffff", 2.004)
	CheckText("rect", rc.OpType, "rect operation type")
	CheckNear(1.01, rc.X, 0.0001, "rect x is rounded")
	CheckNear(4.01, rc.Height, 0.0001, "rect height is rounded")
	CheckText("#ffffff", rc.FillColour, "rect fill colour")
	CheckNear(2, rc.Radius, 0.0001, "rect radius is rounded")

	Dim cl As ReportDrawOp = p.AddClip(0, 0, 100, 50)
	CheckText("clip", cl.OpType, "clip operation type")
	Dim rs As ReportDrawOp = p.AddRestore
	CheckText("restore", rs.OpType, "restore operation type")

	Dim lk As ReportDrawOp = p.AddLink(0, 0, 100, 12, "https://example.com", "")
	CheckText("link", lk.OpType, "link operation type")
	CheckText("https://example.com", lk.Url, "external link url")
	Dim lk2 As ReportDrawOp = p.AddLink(0, 0, 100, 12, "", "chapter-1")
	CheckText("chapter-1", lk2.AnchorName, "internal link anchor")

	Dim a As ReportRenderAnchor = p.AddAnchor("chapter-1", 5.006, 6.004)
	CheckText("chapter-1", a.Name, "anchor name")
	CheckNear(5.01, a.X, 0.0001, "anchor x is rounded")
	CheckNear(6, a.Y, 0.0001, "anchor y is rounded")
	Check(p.Anchors.Size = 1, "one anchor is stored")

	Check(p.Ops.Size = 9, "page operations keep insertion order and count")
	Dim first As ReportDrawOp = p.Ops.Get(0)
	Dim last As ReportDrawOp = p.Ops.Get(p.Ops.Size - 1)
	CheckText("text", first.OpType, "first operation is the text run")
	CheckText("link", last.OpType, "last operation is the second link")
End Sub

'--------------------------------------------------------------- measurement

Private Sub TestMeasurement
	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim mm As ReportB4JMeasure
	mm.Initialize(diags)
	Check(mm.IsAvailable, "measurement adapter is available headless")

	Dim body As ReportTextStyle
	body.Initialize
	body.SetFamily("Arial")
	body.Size = 12

	Dim f As ReportFont = mm.ResolveStyle(body)
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

	Dim large As ReportTextStyle = body.Copy
	large.Size = 24
	CheckNear(w12 * 2, mm.MeasureLine("Hello", large), 0.05, "advance scales with point size")
	Dim f24 As ReportFont = mm.ResolveStyle(large)
	CheckNear(f.Ascent * 2, f24.Ascent, 0.05, "ascent scales with point size")
	CheckNear(f.Descent * 2, f24.Descent, 0.05, "descent scales with point size")

	Dim fractional As ReportTextStyle = body.Copy
	fractional.Size = 10.5
	CheckNear(w12 * 10.5 / 12, mm.MeasureLine("Hello", fractional), 0.05, "fractional point size scales linearly")

	Dim bold As ReportTextStyle = body.Copy
	bold.Bold = True
	Check(mm.MeasureLine("Hello", bold) > w12, "bold face is measured with bold metrics")

	CheckNear(14.4, mm.LineHeight(body), 0.0001, "line height is size times line spacing")
	Dim tight As ReportTextStyle = body.Copy
	tight.LineSpacing = 1
	CheckNear(12, mm.LineHeight(tight), 0.0001, "line spacing one gives the font size")

	Dim one As ReportTextMetrics = mm.MeasureBlock("Hello world", body, 1000)
	Check(one.LineCount = 1, "wide block stays on one line")
	CheckText("Hello world", one.Lines.Get(0), "single line keeps its text")
	CheckNear(mm.MeasureLine("Hello world", body), one.Width, 0.0001, "block width matches line measurement")
	CheckNear(one.LineHeight, one.Height, 0.0001, "one-line block height is one line height")
	CheckNear(f.Ascent, one.Ascent, 0.0001, "block ascent comes from the font")

	Dim narrow As ReportTextMetrics = mm.MeasureBlock("Hello world", body, 40)
	Check(narrow.LineCount = 2, "narrow block wraps at the space")
	CheckText("Hello", narrow.Lines.Get(0), "first wrapped line")
	CheckText("world", narrow.Lines.Get(1), "second wrapped line")
	Check(narrow.Width <= 40.0001, "wrapped lines fit the maximum width")
	CheckNear(narrow.LineHeight * 2, narrow.Height, 0.0001, "two-line block height is two line heights")

	Dim explicit As ReportTextMetrics = mm.MeasureBlock("Hello" & Chr(10) & "world", body, 1000)
	Check(explicit.LineCount = 2, "explicit line break is honoured")
	CheckText("world", explicit.Lines.Get(1), "text after the explicit break")

	Dim trailing As ReportTextMetrics = mm.MeasureBlock("Hello   ", body, 1000)
	CheckText("Hello", trailing.Lines.Get(0), "trailing whitespace is removed")
	CheckNear(w12, trailing.Width, 0.0001, "trailing whitespace does not affect width")

	Dim longWord As ReportTextMetrics = mm.MeasureBlock("Supercalifragilistic", body, 30)
	Check(longWord.LineCount > 1, "over-wide word is broken by character")
	Dim fit As Boolean = True
	For Each lw As Double In longWord.Widths
		If lw > 30.0001 Then fit = False
	Next
	Check(fit, "character-broken lines fit the maximum width")

	Dim empty As ReportTextMetrics = mm.MeasureBlock("", body, 100)
	Check(empty.LineCount = 1, "empty block has one empty line")
	CheckText("", empty.Lines.Get(0), "empty block line is empty")
	CheckNear(0, empty.Width, 0.000001, "empty block has zero width")
	CheckNear(empty.LineHeight, empty.Height, 0.0001, "empty block still has a line height")

	Dim noWrap As ReportTextMetrics = mm.MeasureBlock("Hello world", body, 0)
	Check(noWrap.LineCount = 1, "zero maximum width disables wrapping")

	Dim fb As ReportTextStyle
	fb.Initialize
	fb.SetFamily("NoSuchFamilyXYZ")
	fb.Size = 12
	Dim before As Int = diags.WarningCount
	Dim fallback As ReportFont = mm.ResolveStyle(fb)
	CheckText("Dialog", fallback.Family, "missing family falls back to the platform default")
	Check(fallback.Substituted, "platform default is reported as a substitution")
	Check(diags.WarningCount > before, "substitution records a warning")
	Check(HasDiagnostic(diags, "W-MEA-001"), "substitution warning has a stable code")

	Dim declared As ReportTextStyle
	declared.Initialize
	declared.Family.Add("NoSuchFamilyXYZ")
	declared.Family.Add("Arial")
	declared.Size = 12
	Dim second As ReportFont = mm.ResolveStyle(declared)
	CheckText("Arial", second.Family, "declared fallback order is followed")
	Check(second.Substituted, "using a later declared family is reported")
	CheckText("NoSuchFamilyXYZ", second.RequestedFamily, "primary requested family is retained")

	Dim logical As ReportTextStyle
	logical.Initialize
	logical.SetFamily("sans-serif")
	logical.Size = 12
	Dim logicalFont As ReportFont = mm.ResolveStyle(logical)
	Check(logicalFont.Substituted = False, "logical family is not a substitution")
	Check(logicalFont.HasMetrics, "logical family has metrics")
End Sub

'--------------------------------------------------------------- band layout

Private Sub TestBandLayout
	Dim def As ReportDefinition = MakeBandDefinition
	Dim sec As ReportSection = def.Sections.Get(0)
	Dim measure As ReportB4JMeasure
	Dim diags As ReportDiagnostics
	diags.Initialize
	measure.Initialize(diags)
	Dim layout As ReportBandLayout
	layout.Initialize(diags, measure)

	Dim band As ReportBand = layout.LayoutBand(def, sec, def.Page.ContentWidth, def.Page.ContentHeight, Null)
	Check(band.Width = def.Page.ContentWidth, "band uses the content width")
	Check(band.Elements.Size = 2, "band keeps its children")

	Dim title As ReportLayoutElement = band.Elements.Get(0)
	Dim note As ReportLayoutElement = band.Elements.Get(1)
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
	Dim gdef As ReportDefinition = MakeGridDefinition
	Dim gsec As ReportSection = gdef.Sections.Get(0)
	Dim gband As ReportBand = layout.LayoutBand(gdef, gsec, gdef.Page.ContentWidth, gdef.Page.ContentHeight, Null)
	Dim cell As ReportLayoutElement = gband.Elements.Get(0)
	CheckNear(10, cell.X, 0.0001, "grid cell x is col times cell width")
	CheckNear(10, cell.Y, 0.0001, "grid cell y is row times cell height")
	CheckNear(20, cell.Width, 0.0001, "grid cell width is colSpan times cell width")
	CheckNear(10, cell.Height, 0.0001, "grid cell height is rowSpan times cell height")

	' clip keeps the declared height
	Dim cdef As ReportDefinition = MakeBandDefinition
	Dim csec As ReportSection = cdef.Sections.Get(0)
	Dim clipEl As ReportElement = csec.Elements.Get(0)
	clipEl.Height = 12
	Dim cstyle As ReportStyle = cdef.Styles.Get("body")
	cstyle.Overflow = "clip"
	Dim cband As ReportBand = layout.LayoutBand(cdef, csec, cdef.Page.ContentWidth, cdef.Page.ContentHeight, Null)
	Dim citem As ReportLayoutElement = cband.Elements.Get(0)
	Check(citem.Height = 12, "clip does not grow the element")
	Check(citem.Lines.Size <= 1, "clip limits the laid-out lines")

	' min height
	Dim mdef As ReportDefinition = MakeBandDefinition
	Dim msec As ReportSection = mdef.Sections.Get(0)
	msec.Height = 100
	Dim mband As ReportBand = layout.LayoutBand(mdef, msec, mdef.Page.ContentWidth, mdef.Page.ContentHeight, Null)
	Check(mband.Height >= 100, "band never shrinks below its declared height")

	' element-level align override
	Dim adef As ReportDefinition = MakeBandDefinition
	Dim asec As ReportSection = adef.Sections.Get(0)
	Dim alignEl As ReportElement = asec.Elements.Get(0)
	alignEl.Align = "right"
	Dim aband As ReportBand = layout.LayoutBand(adef, asec, adef.Page.ContentWidth, adef.Page.ContentHeight, Null)
	Dim aitem As ReportLayoutElement = aband.Elements.Get(0)
	Check(aitem.Align = "right", "element align overrides the style")

	' field content comes from the values map
	Dim fdef As ReportDefinition = MakeBandDefinition
	Dim fsec As ReportSection = fdef.Sections.Get(0)
	Dim fieldEl As ReportElement = fsec.Elements.Get(1)
	fieldEl.ElementType = "field"
	fieldEl.ValueExpression = "{X}"
	Dim vals As Map
	vals.Initialize
	vals.Put(fieldEl.Id, "field text")
	Dim fband As ReportBand = layout.LayoutBand(fdef, fsec, fdef.Page.ContentWidth, fdef.Page.ContentHeight, vals)
	Dim fitem As ReportLayoutElement = fband.Elements.Get(1)
	Check(fitem.Content = "field text", "field content is taken from the values map")
End Sub

Private Sub MakeBandDefinition As ReportDefinition
	Dim def As ReportDefinition
	def.Initialize
	def.Page.Width = 200
	def.Page.Height = 300
	def.Page.MarginTop = 0
	def.Page.MarginRight = 0
	def.Page.MarginBottom = 0
	def.Page.MarginLeft = 0

	Dim fd As ReportFontDef
	fd.Initialize
	fd.Name = "body"
	fd.Family.Add("Arial")
	fd.Size = 12
	def.Fonts.Put("body", fd)

	Dim st As ReportStyle
	st.Initialize
	st.Name = "body"
	st.FontName = "body"
	st.Size = 12
	st.LineSpacing = 1.2
	st.Overflow = "grow"
	st.Align = "left"
	st.Valign = "top"
	def.Styles.Put("body", st)

	Dim sec As ReportSection
	sec.Initialize
	sec.SectionType = "Detail"
	sec.Id = "detail"
	sec.Height = 10

	Dim e1 As ReportElement
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

	Dim e2 As ReportElement
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

Private Sub MakeGridDefinition As ReportDefinition
	Dim def As ReportDefinition
	def.Initialize
	def.Page.Width = 100
	def.Page.Height = 50
	def.Page.MarginTop = 0
	def.Page.MarginRight = 0
	def.Page.MarginBottom = 0
	def.Page.MarginLeft = 0
	def.Page.GridColumns = 10
	def.Page.GridRows = 5

	Dim fd As ReportFontDef
	fd.Initialize
	fd.Name = "body"
	fd.Family.Add("Arial")
	fd.Size = 12
	def.Fonts.Put("body", fd)

	Dim st As ReportStyle
	st.Initialize
	st.Name = "body"
	st.FontName = "body"
	st.Size = 12
	st.Overflow = "clip"
	def.Styles.Put("body", st)

	Dim sec As ReportSection
	sec.Initialize
	sec.SectionType = "Detail"
	sec.Id = "detail"
	sec.Height = 0

	Dim e As ReportElement
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
'--------------------------------------------------------------- pagination

Private Sub TestPagination
	Dim fixtures As String = mFixtures
	Dim invDir As String = File.Combine(fixtures, "invoice-basic")

	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(invDir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "invoice template loads: " & FirstErrors(loader.Diagnostics, 3))

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	' params
	Dim params As Map = LoadJsonMap(invDir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	' data
	Dim data As Map = LoadJsonMap(invDir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "invoice data binds: " & FirstErrors(binder.Diagnostics, 3))

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render
	Check(doc.PageCount = 1, "invoice renders to one page")
	Check(diags.HasErrors = False, "invoice pagination has no errors")

	Dim p As ReportRenderPage = doc.PageAt(1)
	Check(p <> Null, "invoice has page 1")
	Check(p.Ops.Size > 0, "invoice page has operations")

	' page footer contains "Page 1 of 1"
	Dim foundPageText As Boolean = False
	For Each op As ReportDrawOp In p.Ops
		If op.OpType = "text" Then
			If op.Text.IndexOf("Page 1 of 1") >= 0 Then foundPageText = True
		End If
	Next
	Check(foundPageText, "invoice page footer says Page 1 of 1")

	' image op present
	Dim hasImage As Boolean = False
	For Each op2 As ReportDrawOp In p.Ops
		If op2.OpType = "image" Then hasImage = True
	Next
	Check(hasImage, "invoice page has an image operation")

	' listing multipage
	Dim listDir As String = File.Combine(fixtures, "listing-multipage")
	Dim lloader As ReportTemplateLoader
	lloader.Initialize
	Dim ldef As ReportDefinition = lloader.LoadFromFile(listDir, "template.repot")
	Check(lloader.Diagnostics.HasErrors = False, "listing template loads")

	Dim lbinder As ReportDataBinder
	lbinder.Initialize(ldef)
	Dim ldata As Map = LoadJsonMap(listDir, "data.json")
	For Each name As String In ldata.Keys
		Dim lo As Object = ldata.Get(name)
		If lo Is List Then
			lbinder.SetDataSource(name, lo)
		Else If lo Is Map Then
			lbinder.SetDataSourceSingle(name, lo)
		End If
	Next
	Dim lparams As Map = LoadJsonMap(listDir, "params.json")
	For Each k As String In lparams.Keys
		lbinder.SetParameter(k, lparams.Get(k))
	Next
	Check(lbinder.Validate, "listing data binds")

	Dim ldiags As ReportDiagnostics
	ldiags.Initialize
	Dim lmeasure As ReportB4JMeasure
	lmeasure.Initialize(ldiags)
	Dim lpag As ReportPaginator
	lpag.Initialize(ldef, lbinder, lmeasure, ldiags)
	Dim ldoc As ReportRenderDocument = lpag.Render
	Check(ldoc.PageCount > 1, "listing renders to more than one page")
	Check(ldiags.HasErrors = False, "listing pagination has no errors")

	' each page has a page header
	Dim allHaveHeader As Boolean = True
	Dim i As Int
	For i = 1 To ldoc.PageCount
		Dim lp As ReportRenderPage = ldoc.PageAt(i)
		Dim hasHeader As Boolean = False
		For Each op3 As ReportDrawOp In lp.Ops
			If op3.OpType = "text" And op3.Text = "Region" Then hasHeader = True
		Next
		If hasHeader = False Then allHaveHeader = False
	Next
	Check(allHaveHeader, "every listing page repeats the page header")
End Sub
'--------------------------------------------------------------- goldens

Private Sub TestGoldens
	Dim names() As String = Array As String("invoice-basic", "listing-multipage")
	For Each name As String In names
		Dim dir As String = File.Combine(mFixtures, name)
		Dim loader As ReportTemplateLoader
		loader.Initialize
		Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
		Check(loader.Diagnostics.HasErrors = False, name & " loads for golden")

		Dim binder As ReportDataBinder
		binder.Initialize(def)
		Dim params As Map = LoadJsonMap(dir, "params.json")
		For Each k As String In params.Keys
			binder.SetParameter(k, params.Get(k))
		Next
		Dim data As Map = LoadJsonMap(dir, "data.json")
		For Each dname As String In data.Keys
			Dim o As Object = data.Get(dname)
			If o Is List Then
				binder.SetDataSource(dname, o)
			Else If o Is Map Then
				binder.SetDataSourceSingle(dname, o)
			End If
		Next
		Check(binder.Validate, name & " binds for golden")

		Dim diags As ReportDiagnostics
		diags.Initialize
		Dim measure As ReportB4JMeasure
		measure.Initialize(diags)
		Dim pag As ReportPaginator
		pag.Initialize(def, binder, measure, diags)
		Dim doc As ReportRenderDocument = pag.Render
		Dim json As String = ReportRenderJsonWriter.ToJson(doc)

		Dim expectedDir As String = File.Combine(dir, "expected")
		Dim goldenPath As String = File.Combine(expectedDir, "layout.json")
		If File.Exists(expectedDir, "layout.json") Then
			Dim existing As String = File.ReadString(expectedDir, "layout.json")
			Check(existing = json, name & " golden matches")
		Else
			File.MakeDir(dir, "expected")
			File.WriteString(expectedDir, "layout.json", json)
			Check(True, name & " golden written")
		End If

		' determinism: second render is identical
		Dim doc2 As ReportRenderDocument = pag.Render
		Dim json2 As String = ReportRenderJsonWriter.ToJson(doc2)
		Check(json = json2, name & " render is deterministic")
	Next
End Sub
'--------------------------------------------------------------- pdf export

Private Sub TestPdfExport
	Dim invDir As String = File.Combine(mFixtures, "invoice-basic")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(invDir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "invoice loads for pdf")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(invDir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(invDir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "invoice binds for pdf")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render

	#If B4A
	Dim outDir As String = File.DirInternal
	#Else
	Dim outDir As String = File.DirApp
	#End If
	Dim outPath As String = File.Combine(outDir, "test-invoice.pdf")
	Dim pdf As ReportPdfExporter
	pdf.Initialize(diags)
	pdf.SourceDir = def.SourceDir
	Dim ok As Boolean = pdf.Export(doc, outPath)
	Check(ok, "invoice pdf exports successfully")
	Check(File.Exists(outDir, "test-invoice.pdf"), "invoice pdf file exists")
	If File.Exists(outDir, "test-invoice.pdf") Then
		Check(pdf.PageCount(outPath) = 1, "invoice pdf has one page")
		Dim txt As String = pdf.ExtractText(outPath)
		Check(txt.IndexOf("INVOICE") >= 0, "invoice pdf contains INVOICE")
		Check(txt.IndexOf("Page 1 of 1") >= 0, "invoice pdf contains page number")
	End If

	' listing
	Dim listDir As String = File.Combine(mFixtures, "listing-multipage")
	Dim lloader As ReportTemplateLoader
	lloader.Initialize
	Dim ldef As ReportDefinition = lloader.LoadFromFile(listDir, "template.repot")
	Check(lloader.Diagnostics.HasErrors = False, "listing loads for pdf")

	Dim lbinder As ReportDataBinder
	lbinder.Initialize(ldef)
	Dim ldata As Map = LoadJsonMap(listDir, "data.json")
	For Each name As String In ldata.Keys
		Dim lo As Object = ldata.Get(name)
		If lo Is List Then
			lbinder.SetDataSource(name, lo)
		Else If lo Is Map Then
			lbinder.SetDataSourceSingle(name, lo)
		End If
	Next
	Dim lparams As Map = LoadJsonMap(listDir, "params.json")
	For Each k As String In lparams.Keys
		lbinder.SetParameter(k, lparams.Get(k))
	Next
	Check(lbinder.Validate, "listing binds for pdf")

	Dim ldiags As ReportDiagnostics
	ldiags.Initialize
	Dim lmeasure As ReportB4JMeasure
	lmeasure.Initialize(ldiags)
	Dim lpag As ReportPaginator
	lpag.Initialize(ldef, lbinder, lmeasure, ldiags)
	Dim ldoc As ReportRenderDocument = lpag.Render

	#If B4A
	Dim loutDir As String = File.DirInternal
	#Else
	Dim loutDir As String = File.DirApp
	#End If
	Dim loutPath As String = File.Combine(loutDir, "test-listing.pdf")
	Dim lpdf As ReportPdfExporter
	lpdf.Initialize(ldiags)
	lpdf.SourceDir = ldef.SourceDir
	Dim lok As Boolean = lpdf.Export(ldoc, loutPath)
	Check(lok, "listing pdf exports successfully")
	If File.Exists(loutDir, "test-listing.pdf") Then
		Check(lpdf.PageCount(loutPath) = ldoc.PageCount, "listing pdf page count matches layout")
	End If
End Sub
'--------------------------------------------------------------- html export

Private Sub TestMultilangPdf
	Dim dir As String = File.Combine(mFixtures, "multilang")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "multilang loads for pdf")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(dir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "multilang binds for pdf")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render

	Dim outDir As String = File.DirApp
	Dim outPath As String = File.Combine(outDir, "test-multilang.pdf")
	Dim pdf As ReportPdfExporter
	pdf.Initialize(diags)
	pdf.SourceDir = def.SourceDir
	pdf.FontFile = File.Combine(File.Combine(mFixtures, "_fonts"), "NotoSans-Regular.ttf")
	pdf.FontFileBold = File.Combine(File.Combine(mFixtures, "_fonts"), "NotoSans-Bold.ttf")
	Dim ok As Boolean = pdf.Export(doc, outPath)
	Check(ok, "multilang pdf exports successfully")
	If File.Exists(outDir, "test-multilang.pdf") Then
		Check(File.Size(outDir, "test-multilang.pdf") > 0, "multilang pdf is non-empty")
		Check(pdf.PageCount(outPath) = doc.PageCount, "multilang pdf page count matches layout")
	End If
End Sub

Private Sub TestRtlArabicPdf
	TestRtlPdfCommon("rtl-arabic", "NotoSansArabic-Regular.ttf", "NotoSansArabic-Bold.ttf", True, "arabic")
End Sub

Private Sub TestRtlHebrewPdf
	TestRtlPdfCommon("rtl-hebrew", "NotoSansHebrew-Regular.ttf", "NotoSansHebrew-Bold.ttf", False, "hebrew")
End Sub

'Common body for the two RTL fixtures. NoQuestion is True only when the
'fixture stays inside the embedded font's actual coverage (Arabic:
'yes; Hebrew: no, Noto Sans Hebrew has no digits/Latin).
Private Sub TestRtlPdfCommon (DirName As String, FontFileName As String, FontBoldName As String, NoQuestion As Boolean, Tag As String)
	Dim dir As String = File.Combine(mFixtures, DirName)
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, Tag & " rtl loads")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(dir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, Tag & " rtl binds")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render

	Dim outDir As String = File.DirApp
	Dim outPath As String = File.Combine(outDir, "test-rtl-" & Tag & ".pdf")
	Dim pdf As ReportPdfExporter
	pdf.Initialize(diags)
	pdf.SourceDir = def.SourceDir
	pdf.FontFile = File.Combine(File.Combine(mFixtures, "_fonts"), FontFileName)
	pdf.FontFileBold = File.Combine(File.Combine(mFixtures, "_fonts"), FontBoldName)
	Dim ok As Boolean = pdf.Export(doc, outPath)
	Check(ok, Tag & " rtl pdf exports")
	If File.Exists(outDir, "test-rtl-" & Tag & ".pdf") = False Then Return
	Check(File.Size(outDir, "test-rtl-" & Tag & ".pdf") > 0, Tag & " rtl pdf non-empty")
	Check(pdf.PageCount(outPath) = 1, Tag & " rtl pdf single page")

	Dim txt As String = pdf.ExtractText(outPath)
	Check(txt.Length > 0, Tag & " rtl pdf extracts text")
	If NoQuestion Then
		Check(txt.IndexOf("?") = -1, Tag & " rtl pdf has no unsupported-glyph filler")
	End If

	If Tag = "arabic" Then
		'PDFBox restores logical-order base letters when extracting RTL
		'text (it normalises presentation forms), so the extractable
		'contract is readable logical Arabic — verified this run that the
		'content stream itself carries shaped, visual-order presentation
		'forms (tools/pdf-probe).
		Check(txt.IndexOf("فاتورة") >= 0, Tag & " rtl pdf extracts logical arabic")
		Check(txt.IndexOf("1042") >= 0, Tag & " rtl pdf keeps embedded digits LTR")
	Else
		'PDFBox restores logical order when extracting RTL text, so the
		'extractable contract is the logical word; visual-order emission
		'was verified at content-stream level during M12 (see notes).
		Check(txt.IndexOf("פריט") >= 0, Tag & " rtl pdf extracts the header word")
	End If
End Sub

Private Sub TestMixedScriptsPdf
	Dim dir As String = File.Combine(mFixtures, "mixed-scripts")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "mixed-scripts loads")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(dir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "mixed-scripts binds")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render

	Dim fontsDir As String = File.Combine(mFixtures, "_fonts")
	Dim outDir As String = File.DirApp
	Dim outPath As String = File.Combine(outDir, "test-mixed-scripts.pdf")
	Dim pdf As ReportPdfExporter
	pdf.Initialize(diags)
	pdf.SourceDir = def.SourceDir
	'primary pair covers Latin + digits; fallback pairs cover Arabic and Hebrew
	pdf.FontFile = File.Combine(fontsDir, "NotoSans-Regular.ttf")
	pdf.FontFileBold = File.Combine(fontsDir, "NotoSans-Bold.ttf")
	pdf.AddEmbeddedFont(File.Combine(fontsDir, "NotoSansArabic-Regular.ttf"), File.Combine(fontsDir, "NotoSansArabic-Bold.ttf"))
	pdf.AddEmbeddedFont(File.Combine(fontsDir, "NotoSansHebrew-Regular.ttf"), File.Combine(fontsDir, "NotoSansHebrew-Bold.ttf"))
	Dim ok As Boolean = pdf.Export(doc, outPath)
	Check(ok, "mixed-scripts pdf exports")
	If File.Exists(outDir, "test-mixed-scripts.pdf") = False Then Return
	Check(File.Size(outDir, "test-mixed-scripts.pdf") > 0, "mixed-scripts pdf non-empty")
	Check(pdf.PageCount(outPath) = 1, "mixed-scripts pdf single page")

	Dim txt As String = pdf.ExtractText(outPath)
	Check(txt.Length > 0, "mixed-scripts pdf extracts text")
	Check(txt.IndexOf("?") = -1, "mixed-scripts pdf has no unsupported-glyph filler")
	Check(txt.IndexOf("Customer") >= 0, "mixed-scripts pdf extracts the latin label")
	Check(txt.IndexOf("Invoice") >= 0, "mixed-scripts pdf extracts the latin subtitle word")
	Check(txt.IndexOf("חשבונית") >= 0, "mixed-scripts pdf extracts logical hebrew")
	Check(txt.IndexOf("1042") >= 0, "mixed-scripts pdf keeps digits")
	Check(txt.IndexOf("شركة") >= 0, "mixed-scripts pdf extracts logical arabic")
	Check(txt.IndexOf("1,250.50") >= 0, "mixed-scripts pdf keeps the decimal amount")

	'BaseDirection = "rtl": export must succeed and extract the same
	'logical text (extraction is direction-independent; the visual
	'punctuation placement is verified with tools/pdf-probe)
	Dim outPath2 As String = File.Combine(outDir, "test-mixed-scripts-rtl.pdf")
	pdf.BaseDirection = "rtl"
	Dim ok2 As Boolean = pdf.Export(doc, outPath2)
	Check(ok2, "mixed-scripts rtl-base pdf exports")
	If File.Exists(outDir, "test-mixed-scripts-rtl.pdf") Then
		Check(pdf.PageCount(outPath2) = 1, "mixed-scripts rtl-base pdf single page")
		Dim txt2 As String = pdf.ExtractText(outPath2)
		Check(txt2.IndexOf("חשבונית") >= 0, "mixed-scripts rtl-base pdf extracts logical hebrew")
		Check(txt2.IndexOf("1042") >= 0, "mixed-scripts rtl-base pdf keeps digits")
	End If
End Sub

Private Sub TestFacade
	Dim dir As String = File.Combine(mFixtures, "invoice-basic")
	Dim r As Repot
	r.Initialize
	Check(r.LoadTemplate(dir, "template.repot"), "facade loads template")
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		r.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(dir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			r.SetDataSource(name, o)
		Else If o Is Map Then
			r.SetDataSourceSingle(name, o)
		End If
	Next
	Dim res As ReportResult = r.Build
	Check(res.Success, "facade build succeeds")
	Check(res.PageCount = 1, "facade reports one page")
	Check(res.RecordCount > 0, "facade counts records")
	Dim outDir As String = File.DirApp
	Check(r.ExportHtml(File.Combine(outDir, "facade.html")), "facade exports html")
	Check(r.ExportPdf(File.Combine(outDir, "facade.pdf")), "facade exports pdf")
	Check(r.ExportCsv(File.Combine(outDir, "facade.csv")), "facade exports csv")
	Dim pdfCount As Int = r.GetPdfPageCount(File.Combine(outDir, "facade.pdf"))
	Check(pdfCount = 1, "facade counts pdf pages (got " & pdfCount & ")")
	Dim pdfText As String = r.ExtractPdfText(File.Combine(outDir, "facade.pdf"))
	Check(pdfText.IndexOf("INVOICE") >= 0, "facade extracts pdf text")
	Check(r.ExtractPdfText(File.Combine(outDir, "missing.pdf")) = "", "facade extract on missing file is empty")
	Check(r.GetPdfPageCount(File.Combine(outDir, "missing.pdf")) = 0, "facade page count on missing file is zero")
End Sub

Private Sub TestHtmlExport
	Dim invDir As String = File.Combine(mFixtures, "invoice-basic")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(invDir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "invoice loads for html")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(invDir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(invDir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "invoice binds for html")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render

	#If B4A
	Dim outDir As String = File.DirInternal
	#Else
	Dim outDir As String = File.DirApp
	#End If
	Dim outPath As String = File.Combine(outDir, "test-invoice.html")
	Dim html As ReportHtmlExporter
	html.Initialize(diags)
	Dim ok As Boolean = html.Export(doc, outPath)
	Check(ok, "invoice html exports successfully")
	Check(File.Exists(outDir, "test-invoice.html"), "invoice html file exists")
	If File.Exists(outDir, "test-invoice.html") Then
		Dim content As String = File.ReadString(outDir, "test-invoice.html")
		Check(content.IndexOf("INVOICE") >= 0, "invoice html contains INVOICE")
		Check(content.IndexOf("page-break-after") >= 0, "invoice html has page break css")
		Check(content.IndexOf("<!DOCTYPE html>") >= 0, "invoice html is a document")
	End If
End Sub
'--------------------------------------------------------------- data export

Private Sub TestDataExport
	Dim invDir As String = File.Combine(mFixtures, "invoice-basic")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(invDir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "invoice loads for data export")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(invDir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(invDir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "invoice binds for data export")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim exp As ReportDataExporter
	exp.Initialize(def, binder, diags)

	#If B4A
	Dim csvPath As String = File.Combine(File.DirInternal, "test-items.csv")
	Check(exp.ExportCsv("Items", csvPath), "csv export succeeds")
	If File.Exists(File.DirInternal, "test-items.csv") Then
		Dim csv As String = File.ReadString(File.DirInternal, "test-items.csv")
		Check(csv.IndexOf("Description") >= 0, "csv has header")
		Check(csv.IndexOf("1200") >= 0 Or csv.IndexOf("1200.0") >= 0, "csv has data")
	End If
	Dim jsonPath As String = File.Combine(File.DirInternal, "test-items.json")
	Check(exp.ExportJson("Items", jsonPath), "json export succeeds")
	If File.Exists(File.DirInternal, "test-items.json") Then
		Dim j As String = File.ReadString(File.DirInternal, "test-items.json")
		Check(j.StartsWith("["), "json is an array")
		Check(j.IndexOf("Description") >= 0, "json has field name")
	End If
	Dim xmlPath As String = File.Combine(File.DirInternal, "test-items.xml")
	Check(exp.ExportXml("Items", xmlPath, "items"), "xml export succeeds")
	If File.Exists(File.DirInternal, "test-items.xml") Then
		Dim x As String = File.ReadString(File.DirInternal, "test-items.xml")
		Check(x.IndexOf("<?xml") >= 0, "xml has declaration")
		Check(x.IndexOf("<row>") >= 0, "xml has row elements")
	End If
	#Else
	Dim csvPath As String = File.Combine(File.DirApp, "test-items.csv")
	Check(exp.ExportCsv("Items", csvPath), "csv export succeeds")
	If File.Exists(File.DirApp, "test-items.csv") Then
		Dim csv As String = File.ReadString(File.DirApp, "test-items.csv")
		Check(csv.IndexOf("Description") >= 0, "csv has header")
		Check(csv.IndexOf("1200") >= 0 Or csv.IndexOf("1200.0") >= 0, "csv has data")
	End If
	Dim jsonPath As String = File.Combine(File.DirApp, "test-items.json")
	Check(exp.ExportJson("Items", jsonPath), "json export succeeds")
	If File.Exists(File.DirApp, "test-items.json") Then
		Dim j As String = File.ReadString(File.DirApp, "test-items.json")
		Check(j.StartsWith("["), "json is an array")
		Check(j.IndexOf("Description") >= 0, "json has field name")
	End If
	Dim xmlPath As String = File.Combine(File.DirApp, "test-items.xml")
	Check(exp.ExportXml("Items", xmlPath, "items"), "xml export succeeds")
	If File.Exists(File.DirApp, "test-items.xml") Then
		Dim x As String = File.ReadString(File.DirApp, "test-items.xml")
		Check(x.IndexOf("<?xml") >= 0, "xml has declaration")
		Check(x.IndexOf("<row>") >= 0, "xml has row elements")
	End If	
	#End If
End Sub
'--------------------------------------------------------------- office export

Private Sub TestOfficeExport
	Dim invDir As String = File.Combine(mFixtures, "invoice-basic")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(invDir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "invoice loads for office export")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(invDir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(invDir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "invoice binds for office export")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim docx As ReportDocxExporter
	docx.Initialize(def, binder, diags)
	Dim docxPath As String = File.Combine(File.DirApp, "test-items.docx")
	Check(docx.Export("Items", docxPath), "docx export succeeds")
	Check(File.Exists(File.DirApp, "test-items.docx"), "docx file exists")

	Dim xlsx As ReportXlsxExporter
	xlsx.Initialize(def, binder, diags)
	Dim xlsxPath As String = File.Combine(File.DirApp, "test-items.xlsx")
	Check(xlsx.Export("Items", xlsxPath), "xlsx export succeeds")
	Check(File.Exists(File.DirApp, "test-items.xlsx"), "xlsx file exists")
End Sub
'--------------------------------------------------------------- expressions

Private Sub TestExpressions
	Dim ctx As ReportEvalContext
	ctx.Initialize
	ctx.Params.Put("X", 5)
	ctx.Params.Put("Name", "  hello  ")
	ctx.CurrentRecord.Initialize
	ctx.CurrentRecord.Put("Qty", 3)
	ctx.CurrentRecord.Put("Price", 10.5)
	ctx.Aggregates.Put("Total", 100)

	Dim ev As ReportExpressionEvaluator
	ev.Initialize

	CheckNear(13, ev.Eval("2 + 3 * 4 - 1", ctx), 0.0001, "arithmetic precedence")
	CheckNear(15, ev.Eval("(2 + 3) * 3", ctx), 0.0001, "parentheses")
	CheckNear(5, ev.Eval("10 / 2", ctx), 0.0001, "division")
	CheckNear(1, ev.Eval("10 - 3 * 3", ctx), 0.0001, "subtraction")

	Check(ev.Eval("2 + 3 = 5", ctx) = True, "equality")
	Check(ev.Eval("2 + 3 <> 6", ctx) = True, "inequality")
	Check(ev.Eval("3 > 2", ctx) = True, "greater than")
	Check(ev.Eval("3 <= 2", ctx) = False, "less-or-equal false")

	Check(ev.Eval("true and false", ctx) = False, "and")
	Check(ev.Eval("true or false", ctx) = True, "or")
	Check(ev.Eval("not false", ctx) = True, "not")
	Check(ev.Eval("not (2 > 3)", ctx) = True, "not parenthesised")

	Check(ev.Eval(Chr(34) & "a" & Chr(34) & " & " & Chr(34) & "b" & Chr(34), ctx) = "ab", "concatenation")

	Dim r1 As Object = ev.Eval("if(2 > 3, 10, 20)", ctx)
	Dim r2 As Object = ev.Eval("if(3 > 2, 10, 20)", ctx)
	Check(20 = r1 Or 20.0 = r1, "if false branch")
	Check(10 = r2 Or 10.0 = r2, "if true branch")

	CheckNear(5, ev.Eval("len(" & Chr(34) & "hello" & Chr(34) & ")", ctx), 0.0001, "len")
	Check(ev.Eval("upper(" & Chr(34) & "hi" & Chr(34) & ")", ctx) = "HI", "upper")
	Check(ev.Eval("lower(" & Chr(34) & "HI" & Chr(34) & ")", ctx) = "hi", "lower")
	Check(ev.Eval("trim(" & Chr(34) & "  x  " & Chr(34) & ")", ctx) = "x", "trim")
	CheckNear(5, ev.Eval("round(4.6)", ctx), 0.0001, "round")
	CheckNear(3, ev.Eval("abs(-3)", ctx), 0.0001, "abs")
	CheckNear(1, ev.Eval("min(2, 5, 1)", ctx), 0.0001, "min")
	CheckNear(5, ev.Eval("max(2, 5, 1)", ctx), 0.0001, "max")

	' field and param resolution
	CheckNear(3, ev.Eval("Qty", ctx), 0.0001, "bare field")
	CheckNear(10.5, ev.Eval("Price", ctx), 0.0001, "bare decimal field")
	CheckNear(100, ev.Eval("Total", ctx), 0.0001, "aggregate")
	CheckNear(5, ev.Eval("param.X", ctx), 0.0001, "param dotted")
	Check(ev.Eval("param.Name", ctx) = "  hello  ", "param string")

	' formatDate
	Dim fd As String = ev.Eval("formatDate(0, " & Chr(34) & "yyyy" & Chr(34) & ")", ctx)
	Check(fd.Length = 4, "formatDate returns a year")
End Sub
'--------------------------------------------------------------- grouping

Private Sub TestGrouping
	Dim dir As String = File.Combine(mFixtures, "statement-grouped")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "statement template loads")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Dim data As Map = LoadJsonMap(dir, "data.json")
	For Each name As String In data.Keys
		Dim o As Object = data.Get(name)
		If o Is List Then
			binder.SetDataSource(name, o)
		Else If o Is Map Then
			binder.SetDataSourceSingle(name, o)
		End If
	Next
	Check(binder.Validate, "statement data binds")

	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim measure As ReportB4JMeasure
	measure.Initialize(diags)
	Dim pag As ReportPaginator
	pag.Initialize(def, binder, measure, diags)
	Dim doc As ReportRenderDocument = pag.Render
	Check(diags.HasErrors = False, "statement pagination has no errors")
	Check(doc.PageCount >= 1, "statement renders at least one page")

	' group header text (month) appears
	Dim foundMonth As Boolean = False
	Dim i As Int
	For i = 1 To doc.PageCount
		Dim p As ReportRenderPage = doc.PageAt(i)
		For Each op As ReportDrawOp In p.Ops
			If op.OpType = "text" Then
				If op.Text.IndexOf("2026-08") >= 0 Then foundMonth = True
				If op.Text.IndexOf("2026") >= 0 Then found2026 = True
			End If
		Next
	Next
	Check(foundMonth, "statement renders a group header")
End Sub
'--------------------------------------------------------------- fixtures

Private Sub TestFixturesLoadAndRoundTrip
	Dim names() As String = Array As String("invoice-basic", "listing-multipage", "statement-grouped")
	For Each name As String In names
		Dim dir As String = File.Combine(mFixtures, name)
		Dim loader As ReportTemplateLoader
		loader.Initialize
		Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
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

		Dim detail As ReportSection = def.SectionByType("Detail")
		Check(detail.DataSet.Length > 0, name & " Detail declares a dataset")
		Check(def.DataSetByName(detail.DataSet) <> Null, name & " Detail dataset exists")

		'Canonical save, reload, save again: the two saves must be identical.
		Dim writer As ReportJsonWriter
		writer.Initialize
		Dim json1 As String = writer.ToJson(def)
		Dim loader2 As ReportTemplateLoader
		loader2.Initialize
		Dim def2 As ReportDefinition = loader2.LoadFromString(json1, dir)
		Check(loader2.Diagnostics.HasErrors = False, name & " reloads its own output: " & FirstErrors(loader2.Diagnostics, 3))
		Dim json2 As String = writer.ToJson(def2)
		CheckText(json1, json2, name & " round-trips through canonical JSON")

		'Loading the same input twice must produce the same canonical output.
		Dim loader3 As ReportTemplateLoader
		loader3.Initialize
		Dim def3 As ReportDefinition = loader3.LoadFromFile(dir, "template.repot")
		Dim json3 As String = writer.ToJson(def3)
		CheckText(json1, json3, name & " is deterministic across loads")
	Next
End Sub

'--------------------------------------------------------------- validation

Private Sub TestValidationFailures
	Dim dir As String = File.Combine(mFixtures, "invoice-basic")
	Dim good As String = File.ReadString(dir, "template.repot")
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
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromString(TemplateText, BaseDir)
	Check(loader.Diagnostics.HasErrors, Label & " is rejected")
	CheckError(loader.Diagnostics, Code, Label & " reports " & Code)
End Sub

'--------------------------------------------------------------- expressions

Private Sub TestExpressionScanner
	Dim diags As ReportDiagnostics
	diags.Initialize
	Dim exprs As List = ReportExpressionRefs.Extract("Page {page.number} of {page.count}", diags, "/test")
	Check(diags.HasErrors = False, "page expressions extract cleanly")
	Check(exprs.Size = 2, "two expressions extract")
	CheckText("page.number", exprs.Get(0), "first expression content")

	Dim nested As List = ReportExpressionRefs.Extract("{if({Amount} > 1000, ""Review"", """")}", diags, "/test")
	Check(diags.HasErrors = False, "nested braces extract cleanly")
	Check(nested.Size = 1, "nested expression is one expression")
	Dim ids As List = ReportExpressionRefs.Identifiers(nested.Get(0), diags, "/test")
	Check(ids.IndexOf("if") >= 0, "nested expression keeps function identifier")
	Check(ids.IndexOf("Amount") >= 0, "nested expression keeps field identifier")
	Check(ids.IndexOf("Review") < 0, "string literal is not an identifier")

	diags.Initialize
	Dim bad As List = ReportExpressionRefs.Extract("Page {page.number", diags, "/test")
	Check(diags.HasErrors, "unbalanced brace is rejected")

	diags.Initialize
	Dim bad2 As List = ReportExpressionRefs.Extract("{}", diags, "/test")
	Check(diags.HasErrors, "empty expression is rejected")

	diags.Initialize
	Dim ids2 As List = ReportExpressionRefs.Identifiers("if({Amount} > 1, ""x"", """")", diags, "/test")
	Check(diags.HasErrors = False, "nested identifiers scan cleanly")

	Dim escaped As String = ReportJsonUtil.JsonQuote("a" & Chr(34) & "b" & Chr(10) & Chr(92) & "c")
	Check(escaped.IndexOf(Chr(92) & Chr(34)) >= 0, "quote escaping")
	Check(escaped.IndexOf(Chr(92) & "n") >= 0, "newline escaping")
	Check(escaped.IndexOf(Chr(92) & Chr(92)) >= 0, "backslash escaping")
End Sub

'--------------------------------------------------------------- binding

Private Sub TestDataBinder
	Dim dir As String = File.Combine(mFixtures, "invoice-basic")
	Dim loader As ReportTemplateLoader
	loader.Initialize
	Dim def As ReportDefinition = loader.LoadFromFile(dir, "template.repot")
	Check(loader.Diagnostics.HasErrors = False, "invoice loads for binding")

	Dim binder As ReportDataBinder
	binder.Initialize(def)
	Dim data As Map = LoadJsonMap(dir, "data.json")
	BindData(binder, def, data)
	Dim params As Map = LoadJsonMap(dir, "params.json")
	For Each k As String In params.Keys
		binder.SetParameter(k, params.Get(k))
	Next
	Check(binder.Validate, "invoice binds with fixture data: " & FirstErrors(binder.Diagnostics, 3))
	Dim items As ReportDataSet = binder.GetDataSet("Items")
	Check(items <> Null, "bound Items dataset exists")
	Check(items.Count = 4, "bound Items has four records")
	Dim customer As ReportDataSet = binder.GetDataSet("Customer")
	Check(customer.Count = 1, "bound single Customer has one record")
	CheckText("Northwind Traders", customer.RecordAt(0).Get("Name"), "bound string value")

	'Missing required parameter.
	Dim b2 As ReportDataBinder
	b2.Initialize(def)
	BindData(b2, def, data)
	Check(b2.Validate = False, "missing required parameter fails validation")
	CheckError(b2.Diagnostics, "E-DATA-011", "missing parameter reports E-DATA-011")

	'Missing dataset.
	Dim b3 As ReportDataBinder
	b3.Initialize(def)
	b3.SetParameter("InvoiceNumber", "INV-1")
	b3.SetParameter("IssuedOn", "2026-01-01")
	Check(b3.Validate = False, "missing dataset fails validation")
	CheckError(b3.Diagnostics, "E-DATA-010", "missing dataset reports E-DATA-010")

	'Wrong dataset shape.
	Dim b4 As ReportDataBinder
	b4.Initialize(def)
	Dim emptyRecord As Map
	emptyRecord.Initialize
	b4.SetDataSourceSingle("Items", emptyRecord)
	CheckError(b4.Diagnostics, "E-DATA-004", "single on a rows dataset reports E-DATA-004")

	'Wrong value type.
	Dim b5 As ReportDataBinder
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
	Dim b6 As ReportDataBinder
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
	Dim withDefault As String = File.ReadString(dir, "template.repot").Replace(target, replacement)
	Dim loaderD As ReportTemplateLoader
	loaderD.Initialize
	Dim defD As ReportDefinition = loaderD.LoadFromString(withDefault, dir)
	Check(loaderD.Diagnostics.HasErrors = False, "template with parameter default loads")
	Dim b7 As ReportDataBinder
	b7.Initialize(defD)
	Check(b7.Parameters.ContainsKey("InvoiceNumber"), "parameter default is applied")
	CheckText("INV-0", b7.Parameters.Get("InvoiceNumber"), "parameter default value")
End Sub

Private Sub BindData (Binder As ReportDataBinder, Def As ReportDefinition, Data As Map)
	For Each name As String In Data.Keys
		Dim dsDef As ReportDataSetDef = Def.DataSetByName(name)
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

Private Sub CheckError (Diags As ReportDiagnostics, Code As String, Message As String)
	Dim found As Boolean = False
	For Each d As ReportDiagnostic In Diags.Items
		If d.Code = Code Then found = True
	Next
	Check(found, Message & " (diagnostic not found)")
End Sub

Private Sub HasDiagnostic (Diags As ReportDiagnostics, Code As String) As Boolean
	For Each d As ReportDiagnostic In Diags.Items
		If d.Code = Code Then Return True
	Next
	Return False
End Sub

Private Sub FirstWarnings (Diags As ReportDiagnostics, Limit As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim n As Int = 0
	For Each d As ReportDiagnostic In Diags.Items
		If d.Severity = "warning" Then
			If n > 0 Then sb.Append("; ")
			sb.Append(d.Code).Append(" ").Append(d.Message)
			n = n + 1
			If n >= Limit Then Exit
		End If
	Next
	Return sb.ToString
End Sub

Private Sub FirstErrors (Diags As ReportDiagnostics, Limit As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim n As Int = 0
	For Each d As ReportDiagnostic In Diags.Items
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
