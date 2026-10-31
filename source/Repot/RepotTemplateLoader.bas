B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Loads a .b4xr JSON template into RepotDefinition and validates it.
'
'The loader converts units once, normalises defaults and reports structured
'diagnostics. It never executes template content.
Sub Class_Globals
	Public Diagnostics As RepotDiagnostics
Private mBaseDir As String
Private mDpi As Double
Private Const AllowedParamTypes As String = "|string|integer|decimal|boolean|datetime|date|"
Private Const AllowedAggregateFunctions As String = "|sum|count|min|max|avg|"
End Sub

Public Sub Initialize
	Diagnostics.Initialize
	mBaseDir = ""
	mDpi = 0
End Sub

Public Sub LoadFromFile (BaseDir As String, FileName As String) As RepotDefinition
	Diagnostics.Initialize
	mBaseDir = BaseDir
	Dim def As RepotDefinition
	def.Initialize
	def.SourceDir = BaseDir

	Dim text As String
	Try
		text = File.ReadString(BaseDir, FileName)
	Catch
		Diagnostics.AddError("E-IO-001", "cannot read template: " & FileName, "")
		Return def
	End Try
	Return LoadFromString(text, BaseDir)
End Sub

Public Sub LoadFromString (Text As String, BaseDir As String) As RepotDefinition
	Diagnostics.Initialize
	mBaseDir = BaseDir
	mDpi = 0

	Dim def As RepotDefinition
	def.Initialize
	def.SourceDir = BaseDir

	If Text.Trim.Length = 0 Then
		Diagnostics.AddError("E-TPL-001", "template is empty", "")
		Return def
	End If

	Dim parser As JSONParser
	Dim root As Object = Null
	Try
		parser.Initialize(Text)
		root = parser.NextObject
	Catch
		Diagnostics.AddError("E-TPL-001", "invalid JSON: " & LastException.Message, "")
		Return def
	End Try

	If (root Is Map) = False Then
		Diagnostics.AddError("E-TPL-002", "template root must be a JSON object", "")
		Return def
	End If

	ParseDefinition(root, def)

	Dim validator As RepotValidator
	validator.Initialize
	validator.Validate(def, Diagnostics, BaseDir)
	Return def
End Sub

'--------------------------------------------------------------- definition

Private Sub ParseDefinition (root As Map, def As RepotDefinition)
	CheckKeys(root, "|schemaVersion|id|name|description|page|fonts|styles|parameters|dataSets|groups|sections|metadata|", "")

	def.SchemaVersion = RepotJsonUtil.StringAt(root, "schemaVersion", "")
	def.Id = RepotJsonUtil.StringAt(root, "id", "")
	def.Name = RepotJsonUtil.StringAt(root, "name", "")
	def.Description = RepotJsonUtil.StringAt(root, "description", "")
	def.Metadata = RepotJsonUtil.MapAt(root, "metadata")

	If def.SchemaVersion.Length = 0 Then
		Diagnostics.AddError("E-TPL-010", "schemaVersion is required", "/schemaVersion")
	Else If def.SchemaVersion <> RepotVersion.SupportedSchemaVersion Then
		Diagnostics.AddError("E-TPL-011", "unsupported schemaVersion '" & def.SchemaVersion & "'; this build reads " & RepotVersion.SupportedSchemaVersion, "/schemaVersion")
	End If
	If def.Id.Length = 0 Then Diagnostics.AddError("E-TPL-012", "report id is required", "/id")
	If def.Name.Length = 0 Then Diagnostics.AddError("E-TPL-013", "report name is required", "/name")

	If RepotJsonUtil.HasKey(root, "page") = False Then
		Diagnostics.AddError("E-TPL-020", "page is required", "/page")
	Else If (RepotJsonUtil.ValueAt(root, "page") Is Map) = False Then
		Diagnostics.AddError("E-TPL-020", "page must be an object", "/page")
	Else
		ParsePage(RepotJsonUtil.MapAt(root, "page"), def)
	End If

	ParseFonts(RepotJsonUtil.MapAt(root, "fonts"), def)
	ParseStyles(RepotJsonUtil.MapAt(root, "styles"), def)
	ParseParameters(RepotJsonUtil.ListAt(root, "parameters"), def)
	ParseDataSets(RepotJsonUtil.ListAt(root, "dataSets"), def)
	ParseGroups(RepotJsonUtil.ListAt(root, "groups"), def)
	ParseSections(RepotJsonUtil.ListAt(root, "sections"), def)
End Sub

'--------------------------------------------------------------- page

Private Sub ParsePage (pageMap As Map, def As RepotDefinition)
	CheckKeys(pageMap, "|size|orientation|margins|grid|footerReserve|dpi|", "/page")

	def.Page.Dpi = RepotJsonUtil.DoubleAt(pageMap, "dpi", 0)
	If def.Page.Dpi < 0 Then
		Diagnostics.AddError("E-TPL-021", "page.dpi must not be negative", "/page/dpi")
		def.Page.Dpi = 0
	End If
	mDpi = def.Page.Dpi

	Dim sizeObj As Object = RepotJsonUtil.ValueAt(pageMap, "size")
	If sizeObj = Null Then
		Diagnostics.AddError("E-TPL-022", "page.size is required", "/page/size")
	Else If sizeObj Is String Then
		def.Page.SizeName = sizeObj
		Dim dims As List = RepotUnits.PageSize(sizeObj)
		If dims.Size = 0 Then
			Diagnostics.AddError("E-TPL-023", "unknown page size '" & sizeObj & "'", "/page/size")
			dims = RepotUnits.PageSize("A4")
			def.Page.SizeName = "A4"
		End If
		def.Page.Width = dims.Get(0)
		def.Page.Height = dims.Get(1)
	Else If sizeObj Is List Then
		Dim dimList As List = sizeObj
		If dimList.Size <> 2 Then
			Diagnostics.AddError("E-TPL-024", "page.size array must be [width, height]", "/page/size")
			Dim a4 As List = RepotUnits.PageSize("A4")
			def.Page.Width = a4.Get(0)
			def.Page.Height = a4.Get(1)
		Else
			def.Page.SizeName = ""
			def.Page.Width = ParseLen(dimList.Get(0), "/page/size/0", 0)
			def.Page.Height = ParseLen(dimList.Get(1), "/page/size/1", 0)
			If def.Page.Width <= 0 Or def.Page.Height <= 0 Then
				Diagnostics.AddError("E-TPL-025", "page dimensions must be positive", "/page/size")
			End If
		End If
	Else
		Diagnostics.AddError("E-TPL-024", "page.size must be a name or [width, height]", "/page/size")
	End If

	Dim orientation As String = RepotJsonUtil.StringAt(pageMap, "orientation", "portrait").Trim.ToLowerCase
	If orientation <> "portrait" And orientation <> "landscape" Then
		Diagnostics.AddError("E-TPL-026", "page.orientation must be portrait or landscape", "/page/orientation")
		orientation = "portrait"
	End If
	def.Page.Orientation = orientation
	If orientation = "landscape" And def.Page.Width < def.Page.Height Then
		Dim tmp As Double = def.Page.Width
		def.Page.Width = def.Page.Height
		def.Page.Height = tmp
	Else If orientation = "portrait" And def.Page.Width > def.Page.Height Then
		tmp = def.Page.Width
		def.Page.Width = def.Page.Height
		def.Page.Height = tmp
	End If

	Dim margins As Map = RepotJsonUtil.MapAt(pageMap, "margins")
	If margins.Size = 0 Then
		Diagnostics.AddError("E-TPL-027", "page.margins is required", "/page/margins")
	Else
		CheckKeys(margins, "|top|right|bottom|left|", "/page/margins")
		def.Page.MarginTop = RequiredLen(margins, "top", "/page/margins/top")
		def.Page.MarginRight = RequiredLen(margins, "right", "/page/margins/right")
		def.Page.MarginBottom = RequiredLen(margins, "bottom", "/page/margins/bottom")
		def.Page.MarginLeft = RequiredLen(margins, "left", "/page/margins/left")
		If def.Page.MarginTop < 0 Or def.Page.MarginRight < 0 Or def.Page.MarginBottom < 0 Or def.Page.MarginLeft < 0 Then
			Diagnostics.AddError("E-TPL-028", "page margins must not be negative", "/page/margins")
		End If
		If def.Page.ContentWidth <= 0 Or def.Page.ContentHeight <= 0 Then
			Diagnostics.AddError("E-TPL-029", "page margins leave no content area", "/page/margins")
		End If
	End If

	If RepotJsonUtil.HasKey(pageMap, "footerReserve") Then
		def.Page.FooterReserve = ParseLen(RepotJsonUtil.ValueAt(pageMap, "footerReserve"), "/page/footerReserve", 0)
	End If

	Dim grid As Map = RepotJsonUtil.MapAt(pageMap, "grid")
	If grid.Size > 0 Then
		CheckKeys(grid, "|columns|rows|cellWidth|cellHeight|", "/page/grid")
		def.Page.GridColumns = RepotJsonUtil.IntAt(grid, "columns", 0)
		def.Page.GridRows = RepotJsonUtil.IntAt(grid, "rows", 0)
		If RepotJsonUtil.HasKey(grid, "cellWidth") Then
			def.Page.CellWidth = ParseLen(RepotJsonUtil.ValueAt(grid, "cellWidth"), "/page/grid/cellWidth", 0)
		End If
		If RepotJsonUtil.HasKey(grid, "cellHeight") Then
			def.Page.CellHeight = ParseLen(RepotJsonUtil.ValueAt(grid, "cellHeight"), "/page/grid/cellHeight", 0)
		End If
		If def.Page.CellWidth <= 0 And def.Page.GridColumns > 0 Then
			def.Page.CellWidth = def.Page.ContentWidth / def.Page.GridColumns
		End If
		If def.Page.CellHeight <= 0 And def.Page.GridRows > 0 Then
			def.Page.CellHeight = def.Page.ContentHeight / def.Page.GridRows
		End If
		If def.Page.GridColumns < 0 Then Diagnostics.AddError("E-TPL-030", "page.grid.columns must not be negative", "/page/grid/columns")
		If def.Page.GridRows < 0 Then Diagnostics.AddError("E-TPL-030", "page.grid.rows must not be negative", "/page/grid/rows")
		If def.Page.CellWidth < 0 Then Diagnostics.AddError("E-TPL-030", "page.grid.cellWidth must not be negative", "/page/grid/cellWidth")
		If def.Page.CellHeight < 0 Then Diagnostics.AddError("E-TPL-030", "page.grid.cellHeight must not be negative", "/page/grid/cellHeight")
		If def.Page.CellWidth = 0 And def.Page.CellHeight = 0 Then
			Diagnostics.AddError("E-TPL-031", "page.grid needs a cell size or a row/column count", "/page/grid")
		End If
	End If
End Sub

'--------------------------------------------------------------- fonts

Private Sub ParseFonts (fontsMap As Map, def As RepotDefinition)
	For Each name As String In fontsMap.Keys
		Dim fm As Map = RepotJsonUtil.MapAt(fontsMap, name)
		Dim path As String = "/fonts/" & name
		If fm.Size = 0 Then
			Diagnostics.AddError("E-TPL-040", "font '" & name & "' must be an object", path)
			Continue
		End If
		CheckKeys(fm, "|family|size|", path)

		Dim f As RepotFontDef
		f.Initialize
		f.Name = name
		Dim famObj As Object = RepotJsonUtil.ValueAt(fm, "family")
		If famObj Is String Then
			f.Family.Add(famObj)
		Else If famObj Is List Then
			Dim famList As List = famObj
			For Each fam As Object In famList
				If fam Is String Then
					f.Family.Add(fam)
				Else
					Diagnostics.AddError("E-TPL-041", "font family entries must be strings", path & "/family")
				End If
			Next
		Else
			Diagnostics.AddError("E-TPL-041", "font family must be a string or an array of strings", path & "/family")
		End If
		If f.Family.Size = 0 Then Diagnostics.AddError("E-TPL-042", "font '" & name & "' has no family", path & "/family")

		f.Size = RepotJsonUtil.DoubleAt(fm, "size", 0)
		If f.Size <= 0 Then Diagnostics.AddError("E-TPL-043", "font '" & name & "' needs a positive size", path & "/size")
		If def.Fonts.ContainsKey(name) Then
			Diagnostics.AddError("E-TPL-044", "duplicate font '" & name & "'", path)
		Else
			def.Fonts.Put(name, f)
		End If
	Next
End Sub

'--------------------------------------------------------------- styles

Private Sub ParseStyles (stylesMap As Map, def As RepotDefinition)
	For Each name As String In stylesMap.Keys
		Dim sm As Map = RepotJsonUtil.MapAt(stylesMap, name)
		Dim path As String = "/styles/" & name
		If sm.Size = 0 Then
			Diagnostics.AddError("E-TPL-050", "style '" & name & "' must be an object", path)
			Continue
		End If
		CheckKeys(sm, "|font|size|bold|italic|underline|colour|align|valign|lineSpacing|padding|border|fill|overflow|format|", path)

		Dim st As RepotStyle
		st.Initialize
		st.Name = name
		st.FontName = RepotJsonUtil.StringAt(sm, "font", "")
		st.Size = RepotJsonUtil.DoubleAt(sm, "size", 0)
		st.Bold = RepotJsonUtil.BoolAt(sm, "bold", False)
		st.Italic = RepotJsonUtil.BoolAt(sm, "italic", False)
		st.Underline = RepotJsonUtil.BoolAt(sm, "underline", False)
		st.Colour = RepotJsonUtil.StringAt(sm, "colour", "")
		st.Align = RepotJsonUtil.StringAt(sm, "align", "left").Trim.ToLowerCase
		st.Valign = RepotJsonUtil.StringAt(sm, "valign", "top").Trim.ToLowerCase
		st.LineSpacing = RepotJsonUtil.DoubleAt(sm, "lineSpacing", 1.2)
		st.Overflow = RepotJsonUtil.StringAt(sm, "overflow", "grow").Trim.ToLowerCase
		st.FillColour = RepotJsonUtil.StringAt(sm, "fill", "")
		st.FormatMap = RepotJsonUtil.MapAt(sm, "format")

		Dim paddingObj As Object = RepotJsonUtil.ValueAt(sm, "padding")
		If paddingObj Is Map Then
			Dim pm As Map = paddingObj
			st.PaddingTop = RepotJsonUtil.DoubleAt(pm, "top", 0)
			st.PaddingRight = RepotJsonUtil.DoubleAt(pm, "right", 0)
			st.PaddingBottom = RepotJsonUtil.DoubleAt(pm, "bottom", 0)
			st.PaddingLeft = RepotJsonUtil.DoubleAt(pm, "left", 0)
		Else If IsNumber(paddingObj) Then
			Dim pad As Double = paddingObj
			st.PaddingTop = pad
			st.PaddingRight = pad
			st.PaddingBottom = pad
			st.PaddingLeft = pad
		End If

		Dim borderObj As Object = RepotJsonUtil.ValueAt(sm, "border")
		If borderObj Is Map Then
			Dim bm As Map = borderObj
			If bm.Size > 0 Then
				st.HasBorder = True
				st.BorderWidth = RepotJsonUtil.DoubleAt(bm, "width", 0.5)
				st.BorderColour = RepotJsonUtil.StringAt(bm, "colour", "")
			End If
		End If

		If st.FontName.Length = 0 Then
			Diagnostics.AddError("E-TPL-051", "style '" & name & "' needs a font", path & "/font")
		End If
		If def.Styles.ContainsKey(name) Then
			Diagnostics.AddError("E-TPL-052", "duplicate style '" & name & "'", path)
		Else
			def.Styles.Put(name, st)
		End If
	Next
End Sub

'--------------------------------------------------------------- parameters

Private Sub ParseParameters (params As List, def As RepotDefinition)
	For i = 0 To params.Size - 1
		Dim pm As Map = RepotJsonUtil.AsMap(params.Get(i))
		Dim path As String = "/parameters/" & i
		If pm.Size = 0 Then
			Diagnostics.AddError("E-TPL-060", "parameter entry must be an object", path)
			Continue
		End If
		CheckKeys(pm, "|name|type|required|default|", path)

		Dim p As RepotParameterDef
		p.Initialize
		p.Name = RepotJsonUtil.StringAt(pm, "name", "")
		p.DataType = RepotJsonUtil.StringAt(pm, "type", "string").Trim.ToLowerCase
		p.Required = RepotJsonUtil.BoolAt(pm, "required", False)
		If RepotJsonUtil.HasKey(pm, "default") Then
			p.HasDefault = True
			p.DefaultValue = RepotJsonUtil.ValueAt(pm, "default")
		End If

		If p.Name.Length = 0 Then
			Diagnostics.AddError("E-TPL-061", "parameter has no name", path)
			Continue
		End If
		If AllowedParamTypes.IndexOf("|" & p.DataType & "|") < 0 Then
			Diagnostics.AddError("E-TPL-062", "unknown parameter type '" & p.DataType & "'", path & "/type")
		End If
		If def.ParameterByName(p.Name) <> Null Then
			Diagnostics.AddError("E-TPL-063", "duplicate parameter '" & p.Name & "'", path & "/name")
		Else
			def.Parameters.Add(p)
		End If
	Next
End Sub

'--------------------------------------------------------------- datasets

Private Sub ParseDataSets (dsList As List, def As RepotDefinition)
	For i = 0 To dsList.Size - 1
		Dim dm As Map = RepotJsonUtil.AsMap(dsList.Get(i))
		Dim path As String = "/dataSets/" & i
		If dm.Size = 0 Then
			Diagnostics.AddError("E-TPL-070", "dataset entry must be an object", path)
			Continue
		End If
		CheckKeys(dm, "|name|kind|fields|aggregates|", path)

		Dim ds As RepotDataSetDef
		ds.Initialize
		ds.Name = RepotJsonUtil.StringAt(dm, "name", "")
		ds.Kind = RepotJsonUtil.StringAt(dm, "kind", "rows").Trim.ToLowerCase
		If ds.Kind <> "rows" And ds.Kind <> "single" Then
			Diagnostics.AddError("E-TPL-071", "dataset kind must be rows or single", path & "/kind")
			ds.Kind = "rows"
		End If

		Dim fields As List = RepotJsonUtil.ListAt(dm, "fields")
		For j = 0 To fields.Size - 1
			Dim fm As Map = RepotJsonUtil.AsMap(fields.Get(j))
			Dim fpath As String = path & "/fields/" & j
			If fm.Size = 0 Then
				Diagnostics.AddError("E-TPL-072", "field entry must be an object", fpath)
				Continue
			End If
			CheckKeys(fm, "|name|type|", fpath)
			Dim f As RepotFieldDef
			f.Initialize
			f.Name = RepotJsonUtil.StringAt(fm, "name", "")
			f.DataType = RepotJsonUtil.StringAt(fm, "type", "string").Trim.ToLowerCase
			If f.Name.Length = 0 Then
				Diagnostics.AddError("E-TPL-073", "field has no name", fpath)
			Else If ds.FieldByName(f.Name) <> Null Then
				Diagnostics.AddError("E-TPL-074", "duplicate field '" & f.Name & "'", fpath & "/name")
			Else
				ds.Fields.Add(f)
			End If
			If AllowedParamTypes.IndexOf("|" & f.DataType & "|") < 0 Then
				Diagnostics.AddError("E-TPL-075", "unknown field type '" & f.DataType & "'", fpath & "/type")
			End If
		Next
		If ds.Fields.Size = 0 Then Diagnostics.AddError("E-TPL-076", "dataset '" & ds.Name & "' has no fields", path & "/fields")

		Dim aggs As List = RepotJsonUtil.ListAt(dm, "aggregates")
		For j = 0 To aggs.Size - 1
			Dim a As RepotAggregateDef = ParseAggregate(aggs.Get(j), "dataset", ds.Name, path & "/aggregates/" & j)
			If a <> Null Then ds.Aggregates.Add(a)
		Next

		If ds.Name.Length = 0 Then
			Diagnostics.AddError("E-TPL-077", "dataset has no name", path)
		Else If def.DataSets.ContainsKey(ds.Name) Then
			Diagnostics.AddError("E-TPL-078", "duplicate dataset '" & ds.Name & "'", path & "/name")
		Else
			def.DataSets.Put(ds.Name, ds)
		End If
	Next
End Sub

'--------------------------------------------------------------- groups

Private Sub ParseGroups (groups As List, def As RepotDefinition)
	For i = 0 To groups.Size - 1
		Dim gm As Map = RepotJsonUtil.AsMap(groups.Get(i))
		Dim path As String = "/groups/" & i
		If gm.Size = 0 Then
			Diagnostics.AddError("E-TPL-080", "group entry must be an object", path)
			Continue
		End If
		CheckKeys(gm, "|id|dataSet|key|sort|repeatHeader|aggregates|", path)

		Dim g As RepotGroupDef
		g.Initialize
		g.Id = RepotJsonUtil.StringAt(gm, "id", "")
		g.DataSet = RepotJsonUtil.StringAt(gm, "dataSet", "")
		g.KeyExpression = RepotJsonUtil.StringAt(gm, "key", "")
		g.RepeatHeader = RepotJsonUtil.BoolAt(gm, "repeatHeader", False)

		Dim sorts As List = RepotJsonUtil.ListAt(gm, "sort")
		For j = 0 To sorts.Size - 1
			Dim sm As Map = RepotJsonUtil.AsMap(sorts.Get(j))
			Dim spath As String = path & "/sort/" & j
			If sm.Size = 0 Then
				Diagnostics.AddError("E-TPL-081", "sort entry must be an object", spath)
				Continue
			End If
			CheckKeys(sm, "|field|direction|", spath)
			Dim s As RepotSortDef
			s.Initialize
			s.FieldName = RepotJsonUtil.StringAt(sm, "field", "")
			s.Direction = RepotJsonUtil.StringAt(sm, "direction", "ascending").Trim.ToLowerCase
			If s.FieldName.Length = 0 Then Diagnostics.AddError("E-TPL-082", "sort entry has no field", spath)
			If s.Direction <> "ascending" And s.Direction <> "descending" Then
				Diagnostics.AddError("E-TPL-083", "sort direction must be ascending or descending", spath & "/direction")
			End If
			g.Sort.Add(s)
		Next

		Dim aggs As List = RepotJsonUtil.ListAt(gm, "aggregates")
		For j = 0 To aggs.Size - 1
			Dim a As RepotAggregateDef = ParseAggregate(aggs.Get(j), "group", g.Id, path & "/aggregates/" & j)
			If a <> Null Then g.Aggregates.Add(a)
		Next

		If g.Id.Length = 0 Then
			Diagnostics.AddError("E-TPL-084", "group has no id", path)
		Else If def.GroupById(g.Id) <> Null Then
			Diagnostics.AddError("E-TPL-085", "duplicate group '" & g.Id & "'", path & "/id")
		Else
			def.Groups.Add(g)
		End If
	Next
End Sub

Private Sub ParseAggregate (o As Object, Scope As String, ScopeId As String, Path As String) As RepotAggregateDef
	Dim am As Map = RepotJsonUtil.AsMap(o)
	If am.Size = 0 Then
		Diagnostics.AddError("E-TPL-090", "aggregate entry must be an object", Path)
		Return Null
	End If
	CheckKeys(am, "|name|function|field|", Path)

	Dim a As RepotAggregateDef
	a.Initialize
	a.Name = RepotJsonUtil.StringAt(am, "name", "")
	a.FunctionName = RepotJsonUtil.StringAt(am, "function", "").Trim.ToLowerCase
	a.FieldName = RepotJsonUtil.StringAt(am, "field", "")
	a.Scope = Scope
	a.ScopeId = ScopeId

	If a.Name.Length = 0 Then Diagnostics.AddError("E-TPL-091", "aggregate has no name", Path)
	If AllowedAggregateFunctions.IndexOf("|" & a.FunctionName & "|") < 0 Then
		Diagnostics.AddError("E-TPL-092", "unknown aggregate function '" & a.FunctionName & "'", Path & "/function")
	End If
	If a.FunctionName <> "count" And a.FieldName.Length = 0 Then
		Diagnostics.AddError("E-TPL-093", "aggregate '" & a.Name & "' requires a field", Path & "/field")
	End If
	Return a
End Sub

'--------------------------------------------------------------- sections

Private Sub ParseSections (sections As List, def As RepotDefinition)
	For i = 0 To sections.Size - 1
		Dim sm As Map = RepotJsonUtil.AsMap(sections.Get(i))
		Dim path As String = "/sections/" & i
		If sm.Size = 0 Then
			Diagnostics.AddError("E-TPL-100", "section entry must be an object", path)
			Continue
		End If
		CheckKeys(sm, "|type|id|height|dataSet|group|elements|keepTogether|pageBreak|visible|", path)

		Dim s As RepotSection
		s.Initialize
		s.SectionType = RepotJsonUtil.StringAt(sm, "type", "")
		s.Id = RepotJsonUtil.StringAt(sm, "id", "")
		s.DataSet = RepotJsonUtil.StringAt(sm, "dataSet", "")
		s.GroupId = RepotJsonUtil.StringAt(sm, "group", "")
		s.KeepTogether = RepotJsonUtil.BoolAt(sm, "keepTogether", False)
		s.PageBreak = RepotJsonUtil.StringAt(sm, "pageBreak", "").Trim.ToLowerCase
		s.VisibleExpression = RepotJsonUtil.StringAt(sm, "visible", "")
		s.SourcePath = path

		If RepotJsonUtil.HasKey(sm, "height") Then
			s.Height = ParseLen(RepotJsonUtil.ValueAt(sm, "height"), path & "/height", 0)
		Else
			Diagnostics.AddError("E-TPL-101", "section height is required", path & "/height")
		End If
		If s.SectionType.Length = 0 Then Diagnostics.AddError("E-TPL-102", "section has no type", path & "/type")
		If s.Id.Length = 0 Then Diagnostics.AddError("E-TPL-103", "section has no id", path & "/id")

		Dim elements As List = RepotJsonUtil.ListAt(sm, "elements")
		For j = 0 To elements.Size - 1
			Dim e As RepotElement = ParseElement(elements.Get(j), path & "/elements/" & j)
			If e <> Null Then s.Elements.Add(e)
		Next

		If def.SectionById(s.Id) <> Null Then
			Diagnostics.AddError("E-TPL-104", "duplicate section id '" & s.Id & "'", path & "/id")
		Else
			def.Sections.Add(s)
		End If
	Next
End Sub

Private Sub ParseElement (o As Object, Path As String) As RepotElement
	Dim em As Map = RepotJsonUtil.AsMap(o)
	If em.Size = 0 Then
		Diagnostics.AddError("E-TPL-110", "element entry must be an object", Path)
		Return Null
	End If
	CheckKeys(em, "|type|id|bounds|cell|style|align|valign|visible|z|text|value|resource|fit|dpi|width|colour|dash|fill|radius|format|", Path)

	Dim e As RepotElement
	e.Initialize
	e.ElementType = RepotJsonUtil.StringAt(em, "type", "")
	e.Id = RepotJsonUtil.StringAt(em, "id", "")
	e.StyleName = RepotJsonUtil.StringAt(em, "style", "")
	e.Align = RepotJsonUtil.StringAt(em, "align", "").Trim.ToLowerCase
	e.Valign = RepotJsonUtil.StringAt(em, "valign", "").Trim.ToLowerCase
	e.VisibleExpression = RepotJsonUtil.StringAt(em, "visible", "")
	e.ZIndex = RepotJsonUtil.IntAt(em, "z", 0)
	e.Text = RepotJsonUtil.StringAt(em, "text", "")
	e.ValueExpression = RepotJsonUtil.StringAt(em, "value", "")
	e.Resource = RepotJsonUtil.StringAt(em, "resource", "")
	e.Fit = RepotJsonUtil.StringAt(em, "fit", "contain").Trim.ToLowerCase
	e.Dpi = RepotJsonUtil.DoubleAt(em, "dpi", 0)
	e.Colour = RepotJsonUtil.StringAt(em, "colour", "")
	e.Dash = RepotJsonUtil.StringAt(em, "dash", "")
	e.FillColour = RepotJsonUtil.StringAt(em, "fill", "")
	e.Radius = RepotJsonUtil.DoubleAt(em, "radius", 0)
	e.FormatMap = RepotJsonUtil.MapAt(em, "format")
	e.SourcePath = Path

	If RepotJsonUtil.HasKey(em, "bounds") Then
		e.HasBounds = True
		Dim bObj As Object = RepotJsonUtil.ValueAt(em, "bounds")
		If (bObj Is List) = False Then
			Diagnostics.AddError("E-TPL-111", "bounds must be an array", Path & "/bounds")
		Else
			Dim b As List = bObj
			If b.Size <> 4 Then
				Diagnostics.AddError("E-TPL-112", "bounds must have four numbers", Path & "/bounds")
			Else
				e.X = ParseLen(b.Get(0), Path & "/bounds/0", 0)
				e.Y = ParseLen(b.Get(1), Path & "/bounds/1", 0)
				e.Width = ParseLen(b.Get(2), Path & "/bounds/2", 0)
				e.Height = ParseLen(b.Get(3), Path & "/bounds/3", 0)
			End If
		End If
	End If

	If RepotJsonUtil.HasKey(em, "cell") Then
		Dim cObj As Object = RepotJsonUtil.ValueAt(em, "cell")
		If (cObj Is Map) = False Then
			Diagnostics.AddError("E-TPL-113", "cell must be an object", Path & "/cell")
		Else
			Dim cm As Map = cObj
			e.UseCell = True
			e.CellCol = RepotJsonUtil.IntAt(cm, "col", -1)
			e.CellRow = RepotJsonUtil.IntAt(cm, "row", -1)
			e.CellColSpan = RepotJsonUtil.IntAt(cm, "colSpan", 1)
			e.CellRowSpan = RepotJsonUtil.IntAt(cm, "rowSpan", 1)
			If e.CellCol < 0 Then Diagnostics.AddError("E-TPL-114", "cell.col is required", Path & "/cell/col")
			If e.CellRow < 0 Then Diagnostics.AddError("E-TPL-114", "cell.row is required", Path & "/cell/row")
			If e.CellColSpan < 1 Then Diagnostics.AddError("E-TPL-115", "cell.colSpan must be at least 1", Path & "/cell/colSpan")
			If e.CellRowSpan < 1 Then Diagnostics.AddError("E-TPL-115", "cell.rowSpan must be at least 1", Path & "/cell/rowSpan")
		End If
	End If

	If e.ElementType = "line" Or e.ElementType = "rect" Then
		e.LineWidth = RepotJsonUtil.DoubleAt(em, "width", 0.5)
	End If

	If e.ElementType.Length = 0 Then Diagnostics.AddError("E-TPL-116", "element has no type", Path & "/type")
	If e.Id.Length = 0 Then Diagnostics.AddError("E-TPL-117", "element has no id", Path & "/id")
	Return e
End Sub

'--------------------------------------------------------------- helpers

Private Sub RequiredLen (m As Map, Key As String, Path As String) As Double
	If m.ContainsKey(Key) = False Then
		Diagnostics.AddError("E-TPL-120", "missing length '" & Key & "'", Path)
		Return 0
	End If
	Return ParseLen(m.Get(Key), Path, 0)
End Sub

Private Sub ParseLen (Value As Object, Path As String, Default As Double) As Double
	Dim d As Double = RepotUnits.ParseLength(Value, mDpi)
	If RepotUnits.LastUnitError.Length > 0 Then
		Diagnostics.AddError("E-UNIT-001", RepotUnits.LastUnitError, Path)
		Return Default
	End If
	Return d
End Sub

Private Sub CheckKeys (m As Map, Allowed As String, Path As String)
	For Each k As String In m.Keys
		If Allowed.IndexOf("|" & k & "|") < 0 Then
			Diagnostics.AddWarning("W-TPL-001", "unknown optional property '" & k & "' ignored", Path & "/" & k)
		End If
	Next
End Sub
