B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Canonical JSON writer for ReportDefinition.
'
'Output is deterministic: object keys are sorted, numbers use an invariant
'dot, and no timestamps or platform paths are written. The writer is used
'for round-trip tests and, later, by the designer.

Sub Class_Globals
	Private mSb As StringBuilder
End Sub

Public Sub Initialize
	mSb.Initialize
End Sub

Public Sub ToJson (Def As ReportDefinition) As String
	mSb.Initialize
	Dim root As Map = DefinitionToMap(Def)
	WriteValue(root, 0)
	mSb.Append(CRLF)
	Return mSb.ToString
End Sub

'--------------------------------------------------------------- model to maps

Private Sub DefinitionToMap (Def As ReportDefinition) As Map
	Dim root As Map
	root.Initialize
	root.Put("schemaVersion", Def.SchemaVersion)
	root.Put("id", Def.Id)
	root.Put("name", Def.Name)
	If Def.Description.Length > 0 Then root.Put("description", Def.Description)
	root.Put("page", PageToMap(Def.Page))
	root.Put("fonts", FontsToMap(Def.Fonts))
	root.Put("styles", StylesToMap(Def.Styles))
	root.Put("parameters", ParametersToList(Def.Parameters))
	root.Put("dataSets", DataSetsToList(Def.DataSets))
	root.Put("groups", GroupsToList(Def.Groups))
	root.Put("sections", SectionsToList(Def.Sections))
	If Def.Metadata.Size > 0 Then root.Put("metadata", Def.Metadata)
	Return root
End Sub

Private Sub PageToMap (Page As ReportPageSetup) As Map
	Dim m As Map
	m.Initialize
	If Page.SizeName.Length > 0 Then
		m.Put("size", Page.SizeName)
	Else
		Dim sizeList As List
		sizeList.Initialize
		sizeList.Add(Page.Width)
		sizeList.Add(Page.Height)
		m.Put("size", sizeList)
	End If
	m.Put("orientation", Page.Orientation)
	Dim margins As Map
	margins.Initialize
	margins.Put("top", Page.MarginTop)
	margins.Put("right", Page.MarginRight)
	margins.Put("bottom", Page.MarginBottom)
	margins.Put("left", Page.MarginLeft)
	m.Put("margins", margins)
	If Page.Dpi > 0 Then m.Put("dpi", Page.Dpi)
	If Page.FooterReserve > 0 Then m.Put("footerReserve", Page.FooterReserve)
	If Page.GridColumns > 0 Or Page.GridRows > 0 Or Page.CellWidth > 0 Or Page.CellHeight > 0 Then
		Dim grid As Map
		grid.Initialize
		If Page.GridColumns > 0 Then grid.Put("columns", Page.GridColumns)
		If Page.GridRows > 0 Then grid.Put("rows", Page.GridRows)
		If Page.CellWidth > 0 Then grid.Put("cellWidth", Page.CellWidth)
		If Page.CellHeight > 0 Then grid.Put("cellHeight", Page.CellHeight)
		m.Put("grid", grid)
	End If
	Return m
End Sub

Private Sub FontsToMap (Fonts As Map) As Map
	Dim out As Map
	out.Initialize
	For Each name As String In Fonts.Keys
		Dim f As ReportFontDef = Fonts.Get(name)
		Dim m As Map
		m.Initialize
		m.Put("family", f.Family)
		m.Put("size", f.Size)
		out.Put(name, m)
	Next
	Return out
End Sub

Private Sub StylesToMap (Styles As Map) As Map
	Dim out As Map
	out.Initialize
	For Each name As String In Styles.Keys
		Dim st As ReportStyle = Styles.Get(name)
		Dim m As Map
		m.Initialize
		m.Put("font", st.FontName)
		m.Put("size", st.Size)
		m.Put("bold", st.Bold)
		m.Put("italic", st.Italic)
		m.Put("underline", st.Underline)
		If st.Colour.Length > 0 Then m.Put("colour", st.Colour)
		m.Put("align", st.Align)
		m.Put("valign", st.Valign)
		m.Put("lineSpacing", st.LineSpacing)
		m.Put("overflow", st.Overflow)
		If st.PaddingTop <> 0 Or st.PaddingRight <> 0 Or st.PaddingBottom <> 0 Or st.PaddingLeft <> 0 Then
			Dim pad As Map
			pad.Initialize
			pad.Put("top", st.PaddingTop)
			pad.Put("right", st.PaddingRight)
			pad.Put("bottom", st.PaddingBottom)
			pad.Put("left", st.PaddingLeft)
			m.Put("padding", pad)
		End If
		If st.HasBorder Then
			Dim border As Map
			border.Initialize
			border.Put("width", st.BorderWidth)
			If st.BorderColour.Length > 0 Then border.Put("colour", st.BorderColour)
			m.Put("border", border)
		End If
		If st.FillColour.Length > 0 Then m.Put("fill", st.FillColour)
		If st.FormatMap.Size > 0 Then m.Put("format", st.FormatMap)
		out.Put(name, m)
	Next
	Return out
End Sub

Private Sub ParametersToList (Parameters As List) As List
	Dim out As List
	out.Initialize
	For Each p As ReportParameterDef In Parameters
		Dim m As Map
		m.Initialize
		m.Put("name", p.Name)
		m.Put("type", p.DataType)
		m.Put("required", p.Required)
		If p.HasDefault Then m.Put("default", p.DefaultValue)
		out.Add(m)
	Next
	Return out
End Sub

Private Sub DataSetsToList (DataSets As Map) As List
	Dim out As List
	out.Initialize
	'Write in declaration order when possible: sort names for determinism.
	Dim names As List
	names.Initialize
	For Each n As String In DataSets.Keys
		names.Add(n)
	Next
	names.Sort(True)
	For Each name As String In names
		Dim ds As ReportDataSetDef = DataSets.Get(name)
		Dim m As Map
		m.Initialize
		m.Put("name", ds.Name)
		m.Put("kind", ds.Kind)
		Dim fields As List
		fields.Initialize
		For Each f As ReportFieldDef In ds.Fields
			Dim fm As Map
			fm.Initialize
			fm.Put("name", f.Name)
			fm.Put("type", f.DataType)
			fields.Add(fm)
		Next
		m.Put("fields", fields)
		If ds.Aggregates.Size > 0 Then m.Put("aggregates", AggregatesToList(ds.Aggregates))
		out.Add(m)
	Next
	Return out
End Sub

Private Sub AggregatesToList (Aggregates As List) As List
	Dim out As List
	out.Initialize
	For Each a As ReportAggregateDef In Aggregates
		Dim m As Map
		m.Initialize
		m.Put("name", a.Name)
		m.Put("function", a.FunctionName)
		If a.FieldName.Length > 0 Then m.Put("field", a.FieldName)
		out.Add(m)
	Next
	Return out
End Sub

Private Sub GroupsToList (Groups As List) As List
	Dim out As List
	out.Initialize
	For Each g As ReportGroupDef In Groups
		Dim m As Map
		m.Initialize
		m.Put("id", g.Id)
		m.Put("dataSet", g.DataSet)
		m.Put("key", g.KeyExpression)
		If g.Sort.Size > 0 Then
			Dim sorts As List
			sorts.Initialize
			For Each s As ReportSortDef In g.Sort
				Dim sm As Map
				sm.Initialize
				sm.Put("field", s.FieldName)
				sm.Put("direction", s.Direction)
				sorts.Add(sm)
			Next
			m.Put("sort", sorts)
		End If
		m.Put("repeatHeader", g.RepeatHeader)
		If g.Aggregates.Size > 0 Then m.Put("aggregates", AggregatesToList(g.Aggregates))
		out.Add(m)
	Next
	Return out
End Sub

Private Sub SectionsToList (Sections As List) As List
	Dim out As List
	out.Initialize
	For Each s As ReportSection In Sections
		Dim m As Map
		m.Initialize
		m.Put("type", s.SectionType)
		m.Put("id", s.Id)
		m.Put("height", s.Height)
		If s.DataSet.Length > 0 Then m.Put("dataSet", s.DataSet)
		If s.GroupId.Length > 0 Then m.Put("group", s.GroupId)
		If s.KeepTogether Then m.Put("keepTogether", s.KeepTogether)
		If s.PageBreak.Length > 0 Then m.Put("pageBreak", s.PageBreak)
		If s.VisibleExpression.Length > 0 Then m.Put("visible", s.VisibleExpression)
		Dim elements As List
		elements.Initialize
		For Each e As ReportElement In s.Elements
			elements.Add(ElementToMap(e))
		Next
		m.Put("elements", elements)
		out.Add(m)
	Next
	Return out
End Sub

Private Sub ElementToMap (e As ReportElement) As Map
	Dim m As Map
	m.Initialize
	m.Put("type", e.ElementType)
	m.Put("id", e.Id)
	If e.HasBounds Then
		Dim b As List
		b.Initialize
		b.Add(e.X)
		b.Add(e.Y)
		b.Add(e.Width)
		b.Add(e.Height)
		m.Put("bounds", b)
	End If
	If e.UseCell Then
		Dim c As Map
		c.Initialize
		c.Put("col", e.CellCol)
		c.Put("row", e.CellRow)
		c.Put("colSpan", e.CellColSpan)
		c.Put("rowSpan", e.CellRowSpan)
		m.Put("cell", c)
	End If
	If e.StyleName.Length > 0 Then m.Put("style", e.StyleName)
	If e.Align.Length > 0 Then m.Put("align", e.Align)
	If e.Valign.Length > 0 Then m.Put("valign", e.Valign)
	If e.VisibleExpression.Length > 0 Then m.Put("visible", e.VisibleExpression)
	If e.ZIndex <> 0 Then m.Put("z", e.ZIndex)
	If e.ElementType = "text" Then m.Put("text", e.Text)
	If e.ElementType = "field" Then m.Put("value", e.ValueExpression)
	If e.ElementType = "image" Then
		m.Put("resource", e.Resource)
		m.Put("fit", e.Fit)
		If e.Dpi > 0 Then m.Put("dpi", e.Dpi)
	End If
	If e.ElementType = "line" Or e.ElementType = "rect" Then
		m.Put("width", e.LineWidth)
	End If
	If e.Colour.Length > 0 Then m.Put("colour", e.Colour)
	If e.Dash.Length > 0 Then m.Put("dash", e.Dash)
	If e.FillColour.Length > 0 Then m.Put("fill", e.FillColour)
	If e.Radius <> 0 Then m.Put("radius", e.Radius)
	If e.FormatMap.Size > 0 Then m.Put("format", e.FormatMap)
	Return m
End Sub

'--------------------------------------------------------------- JSON writer

Private Sub WriteValue (Value As Object, Indent As Int)
	If Value = Null Then
		mSb.Append("null")
	Else If Value Is String Then
		mSb.Append(ReportJsonUtil.JsonQuote(Value))
	Else If Value Is Boolean Then
		If Value Then
			mSb.Append("true")
		Else
			mSb.Append("false")
		End If
	Else If IsNumber(Value) Then
		Dim d As Double = Value
		mSb.Append(ReportUnits.FormatNumber(d, 4))
	Else If Value Is Map Then
		WriteMap(Value, Indent)
	Else If Value Is List Then
		WriteList(Value, Indent)
	Else
		mSb.Append("null")
	End If
End Sub

Private Sub WriteMap (Value As Map, Indent As Int)
	If Value.Size = 0 Then
		mSb.Append("{}")
		Return
	End If
	mSb.Append("{").Append(CRLF)
	Dim keys As List
	keys.Initialize
	For Each k As String In Value.Keys
		keys.Add(k)
	Next
	keys.Sort(True)
	For i = 0 To keys.Size - 1
		Dim k As String = keys.Get(i)
		mSb.Append(Spaces(Indent + 2)).Append(ReportJsonUtil.JsonQuote(k)).Append(": ")
		WriteValue(Value.Get(k), Indent + 2)
		If i < keys.Size - 1 Then mSb.Append(",")
		mSb.Append(CRLF)
	Next
	mSb.Append(Spaces(Indent)).Append("}")
End Sub

Private Sub WriteList (Value As List, Indent As Int)
	If Value.Size = 0 Then
		mSb.Append("[]")
		Return
	End If
	mSb.Append("[").Append(CRLF)
	For i = 0 To Value.Size - 1
		mSb.Append(Spaces(Indent + 2))
		WriteValue(Value.Get(i), Indent + 2)
		If i < Value.Size - 1 Then mSb.Append(",")
		mSb.Append(CRLF)
	Next
	mSb.Append(Spaces(Indent)).Append("]")
End Sub

Private Sub Spaces (Count As Int) As String
	Dim sb As StringBuilder
	sb.Initialize
	For i = 1 To Count
		sb.Append(" ")
	Next
	Return sb.ToString
End Sub
