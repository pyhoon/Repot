B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Semantic validation of a loaded definition.
'
'The loader already reports syntax and conversion problems. This pass checks
'references, uniqueness, section rules and expression identifiers. Diagnostics
'carry the source path and element id so a designer can highlight them.

Sub Class_Globals
	Private mDef As ReportDefinition
	Private mDiags As ReportDiagnostics
	Private mBaseDir As String
	Private mParams As Map
	Private mDataSets As Map
	Private mGroups As Map
	Private mStyles As Map
	Private mFonts As Map
	Private mAggs As Map
	Private mElementIds As Map
	Private mSectionTypes As Map
	Private Const AllowedSectionTypes As String = "|ReportHeader|PageHeader|GroupHeader|Detail|GroupFooter|PageFooter|ReportFooter|"
	Private Const AllowedElementTypes As String = "|text|field|image|line|rect|"
	Private Const AllowedFieldTypes As String = "|string|integer|decimal|boolean|datetime|date|"
	Private Const AllowedFunctions As String = "|if|len|upper|lower|trim|round|abs|min|max|formatdate|sum|count|avg|"
End Sub

Public Sub Initialize
	mParams.Initialize
	mDataSets.Initialize
	mGroups.Initialize
	mStyles.Initialize
	mFonts.Initialize
	mAggs.Initialize
	mElementIds.Initialize
	mSectionTypes.Initialize
End Sub

Public Sub Validate (Def As ReportDefinition, Diags As ReportDiagnostics, BaseDir As String)
	mDef = Def
	mDiags = Diags
	mBaseDir = BaseDir
	mParams = NewMap
	mDataSets = NewMap
	mGroups = NewMap
	mStyles = NewMap
	mFonts = NewMap
	mAggs = NewMap
	mElementIds = NewMap
	mSectionTypes = NewMap

	IndexFonts
	IndexStyles
	IndexParameters
	IndexDataSets
	IndexGroups
	IndexAggregates
	ValidatePage
	ValidateSections
End Sub

Private Sub NewMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

'--------------------------------------------------------------- indexes

Private Sub IndexFonts
	For Each name As String In mDef.Fonts.Keys
		Dim f As ReportFontDef = mDef.Fonts.Get(name)
		mFonts.Put(name, f)
		If f.Family.Size = 0 Then
			mDiags.AddError("E-VAL-001", "font '" & name & "' has no family", "/fonts/" & name)
		End If
		If f.Size <= 0 Then
			mDiags.AddError("E-VAL-002", "font '" & name & "' needs a positive size", "/fonts/" & name & "/size")
		End If
	Next
End Sub

Private Sub IndexStyles
	For Each name As String In mDef.Styles.Keys
		Dim st As ReportStyle = mDef.Styles.Get(name)
		mStyles.Put(name, st)
		If st.FontName.Length > 0 And mFonts.ContainsKey(st.FontName) = False Then
			mDiags.AddError("E-VAL-010", "style '" & name & "' references unknown font '" & st.FontName & "'", "/styles/" & name & "/font")
		End If
		If st.Align <> "left" And st.Align <> "center" And st.Align <> "right" Then
			mDiags.AddError("E-VAL-011", "style '" & name & "' has invalid align '" & st.Align & "'", "/styles/" & name & "/align")
		End If
		If st.Valign <> "top" And st.Valign <> "middle" And st.Valign <> "bottom" Then
			mDiags.AddError("E-VAL-012", "style '" & name & "' has invalid valign '" & st.Valign & "'", "/styles/" & name & "/valign")
		End If
		If st.Overflow <> "grow" And st.Overflow <> "clip" And st.Overflow <> "ellipsis" Then
			mDiags.AddError("E-VAL-013", "style '" & name & "' has invalid overflow '" & st.Overflow & "'", "/styles/" & name & "/overflow")
		End If
		If st.LineSpacing <= 0 Then
			mDiags.AddError("E-VAL-014", "style '" & name & "' needs a positive lineSpacing", "/styles/" & name & "/lineSpacing")
		End If
		If st.Colour.Length > 0 And IsColour(st.Colour) = False Then
			mDiags.AddError("E-VAL-015", "style '" & name & "' has invalid colour '" & st.Colour & "'", "/styles/" & name & "/colour")
		End If
	Next
End Sub

Private Sub IndexParameters
	For Each p As ReportParameterDef In mDef.Parameters
		mParams.Put(p.Name, p)
		If AllowedFieldTypes.IndexOf("|" & p.DataType & "|") < 0 Then
			mDiags.AddError("E-VAL-020", "parameter '" & p.Name & "' has unknown type '" & p.DataType & "'", "/parameters")
		End If
	Next
End Sub

Private Sub IndexDataSets
	For Each name As String In mDef.DataSets.Keys
		Dim ds As ReportDataSetDef = mDef.DataSets.Get(name)
		mDataSets.Put(name, ds)
		If ds.Kind <> "rows" And ds.Kind <> "single" Then
			mDiags.AddError("E-VAL-030", "dataset '" & name & "' has invalid kind '" & ds.Kind & "'", "/dataSets/" & name)
		End If
		If ds.Fields.Size = 0 Then
			mDiags.AddError("E-VAL-031", "dataset '" & name & "' has no fields", "/dataSets/" & name & "/fields")
		End If
		For Each f As ReportFieldDef In ds.Fields
			If AllowedFieldTypes.IndexOf("|" & f.DataType & "|") < 0 Then
				mDiags.AddError("E-VAL-032", "field '" & name & "." & f.Name & "' has unknown type '" & f.DataType & "'", "/dataSets/" & name & "/fields")
			End If
		Next
	Next
End Sub

Private Sub IndexGroups
	For Each g As ReportGroupDef In mDef.Groups
		mGroups.Put(g.Id, g)
		If g.DataSet.Length = 0 Then
			mDiags.AddError("E-VAL-040", "group '" & g.Id & "' has no dataSet", "/groups/" & g.Id)
		Else If mDataSets.ContainsKey(g.DataSet) = False Then
			mDiags.AddError("E-VAL-041", "group '" & g.Id & "' references unknown dataSet '" & g.DataSet & "'", "/groups/" & g.Id & "/dataSet")
		End If
		If g.KeyExpression.Length = 0 Then
			mDiags.AddError("E-VAL-042", "group '" & g.Id & "' has no key", "/groups/" & g.Id & "/key")
		End If
		For Each s As ReportSortDef In g.Sort
			Dim ds As ReportDataSetDef = DataSetOrNull(g.DataSet)
			If ds <> Null Then
				If ds.FieldByName(s.FieldName) = Null Then
					mDiags.AddError("E-VAL-043", "group '" & g.Id & "' sorts by unknown field '" & s.FieldName & "'", "/groups/" & g.Id & "/sort")
				End If
			End If
		Next
	Next
End Sub

Private Sub IndexAggregates
	'Dataset aggregates.
	For Each name As String In mDef.DataSets.Keys
		Dim ds As ReportDataSetDef = mDef.DataSets.Get(name)
		For Each a As ReportAggregateDef In ds.Aggregates
			RegisterAggregate(a, ds.Name, "/dataSets/" & name & "/aggregates")
		Next
	Next
	'Group aggregates.
	For Each g As ReportGroupDef In mDef.Groups
		For Each a As ReportAggregateDef In g.Aggregates
			RegisterAggregate(a, g.DataSet, "/groups/" & g.Id & "/aggregates")
		Next
	Next
End Sub

Private Sub RegisterAggregate (a As ReportAggregateDef, DataSetName As String, Path As String)
	If a.Name.Length = 0 Then Return
	If mAggs.ContainsKey(a.Name) Then
		mDiags.AddError("E-VAL-050", "duplicate aggregate name '" & a.Name & "' (aggregate names are document-unique)", Path)
		Return
	End If
	mAggs.Put(a.Name, a)
	Dim ds As ReportDataSetDef = DataSetOrNull(DataSetName)
	If ds = Null Then
		mDiags.AddError("E-VAL-051", "aggregate '" & a.Name & "' has no dataset", Path)
	Else If a.FunctionName <> "count" And a.FieldName.Length > 0 Then
		If ds.FieldByName(a.FieldName) = Null Then
			mDiags.AddError("E-VAL-052", "aggregate '" & a.Name & "' references unknown field '" & a.FieldName & "'", Path)
		End If
	End If
End Sub

Private Sub DataSetOrNull (Name As String) As ReportDataSetDef
	If Name.Length > 0 Then
		If mDataSets.ContainsKey(Name) Then Return mDataSets.Get(Name)
	End If
	Return Null
End Sub

'--------------------------------------------------------------- page

Private Sub ValidatePage
	If mDef.Page.Width <= 0 Or mDef.Page.Height <= 0 Then
		mDiags.AddError("E-VAL-060", "page dimensions must be positive", "/page")
	End If
	If mDef.Page.ContentWidth <= 0 Or mDef.Page.ContentHeight <= 0 Then
		mDiags.AddError("E-VAL-061", "page margins leave no content area", "/page/margins")
	End If
End Sub

'--------------------------------------------------------------- sections

Private Sub ValidateSections
	Dim detailCount As Int = 0
	For Each s As ReportSection In mDef.Sections
		ValidateSection(s)
		If s.SectionType = "Detail" Then detailCount = detailCount + 1
	Next
	If detailCount = 0 Then mDiags.AddError("E-VAL-070", "no Detail section", "/sections")

	For Each t As String In mSectionTypes.Keys
		Dim count As Int = mSectionTypes.Get(t)
		If t = "ReportHeader" Or t = "PageHeader" Or t = "PageFooter" Or t = "ReportFooter" Or t = "Detail" Then
			If count > 1 Then
				mDiags.AddError("E-VAL-071", "section type " & t & " may appear only once", "/sections")
			End If
		End If
	Next
End Sub

Private Sub ValidateSection (s As ReportSection)
	Dim path As String = s.SourcePath
	If AllowedSectionTypes.IndexOf("|" & s.SectionType & "|") < 0 Then
		mDiags.AddError("E-VAL-072", "unknown section type '" & s.SectionType & "'", path & "/type")
	End If
	If s.Height < 0 Then
		mDiags.AddError("E-VAL-073", "section height must not be negative", path & "/height")
	End If
	If s.PageBreak.Length > 0 And s.PageBreak <> "before" And s.PageBreak <> "after" Then
		mDiags.AddError("E-VAL-074", "pageBreak must be before or after", path & "/pageBreak")
	End If
	If mSectionTypes.ContainsKey(s.SectionType) Then
		mSectionTypes.Put(s.SectionType, mSectionTypes.Get(s.SectionType) + 1)
	Else
		mSectionTypes.Put(s.SectionType, 1)
	End If

	Dim expressionDataSet As String = ""
	Dim isGroup As Boolean = s.SectionType = "GroupHeader" Or s.SectionType = "GroupFooter"
	If s.SectionType = "Detail" Then
		If s.DataSet.Length = 0 Then
			mDiags.AddError("E-VAL-080", "Detail section has no dataSet", path & "/dataSet")
		Else If mDataSets.ContainsKey(s.DataSet) = False Then
			mDiags.AddError("E-VAL-081", "Detail section references unknown dataSet '" & s.DataSet & "'", path & "/dataSet")
		Else
			expressionDataSet = s.DataSet
		End If
		If s.GroupId.Length > 0 Then
			mDiags.AddError("E-VAL-082", "Detail section must not reference a group", path & "/group")
		End If
	Else If isGroup Then
		If s.GroupId.Length = 0 Then
			mDiags.AddError("E-VAL-083", s.SectionType & " section has no group", path & "/group")
		Else If mGroups.ContainsKey(s.GroupId) = False Then
			mDiags.AddError("E-VAL-084", s.SectionType & " references unknown group '" & s.GroupId & "'", path & "/group")
		Else
			Dim g As ReportGroupDef = mGroups.Get(s.GroupId)
			expressionDataSet = g.DataSet
		End If
		If s.DataSet.Length > 0 Then
			mDiags.AddError("E-VAL-085", s.SectionType & " section must not set dataSet; use group", path & "/dataSet")
		End If
	Else
		If s.DataSet.Length > 0 Then
			mDiags.AddError("E-VAL-086", s.SectionType & " section must not set dataSet", path & "/dataSet")
		End If
		If s.GroupId.Length > 0 Then
			mDiags.AddError("E-VAL-087", s.SectionType & " section must not set group", path & "/group")
		End If
	End If

	If s.VisibleExpression.Length > 0 Then
		ValidateExpression(s.VisibleExpression, expressionDataSet, path & "/visible", s.Id)
	End If

	For Each e As ReportElement In s.Elements
		ValidateElement(e, s, expressionDataSet)
	Next
End Sub

'--------------------------------------------------------------- elements

Private Sub ValidateElement (e As ReportElement, s As ReportSection, SectionDataSet As String)
	Dim path As String = e.SourcePath
	Dim where As String = s.Id & "/" & e.Id

	If mElementIds.ContainsKey(e.Id) Then
		mDiags.AddErrorAt("E-VAL-090", "duplicate element id '" & e.Id & "'", path & "/id", e.Id)
	Else
		mElementIds.Put(e.Id, True)
	End If

	If AllowedElementTypes.IndexOf("|" & e.ElementType & "|") < 0 Then
		mDiags.AddErrorAt("E-VAL-091", "unknown element type '" & e.ElementType & "'", path & "/type", e.Id)
	End If

	If e.HasBounds = e.UseCell Then
		mDiags.AddErrorAt("E-VAL-092", "exactly one of bounds or cell is required", path, e.Id)
	End If
	If e.HasBounds Then
		If e.Width < 0 Or e.Height < 0 Then
			mDiags.AddErrorAt("E-VAL-093", "bounds width and height must not be negative", path & "/bounds", e.Id)
		End If
	End If
	If e.UseCell Then
		If mDef.Page.GridColumns > 0 And e.CellCol >= 0 And e.CellColSpan > 0 Then
			If e.CellCol + e.CellColSpan > mDef.Page.GridColumns Then
				mDiags.AddErrorAt("E-VAL-094", "cell exceeds the " & mDef.Page.GridColumns & " grid columns", path & "/cell", e.Id)
			End If
		End If
		If mDef.Page.CellWidth <= 0 Then
			mDiags.AddErrorAt("E-VAL-095", "cell positioning requires page.grid.cellWidth or columns", path & "/cell", e.Id)
		End If
		If mDef.Page.CellHeight <= 0 Then
			mDiags.AddErrorAt("E-VAL-095", "cell positioning requires page.grid.cellHeight or rows", path & "/cell", e.Id)
		End If
	End If

	If e.StyleName.Length > 0 And mStyles.ContainsKey(e.StyleName) = False Then
		mDiags.AddErrorAt("E-VAL-096", "unknown style '" & e.StyleName & "'", path & "/style", e.Id)
	End If
	If e.Align.Length > 0 And e.Align <> "left" And e.Align <> "center" And e.Align <> "right" Then
		mDiags.AddErrorAt("E-VAL-107", "element align must be left, center or right", path & "/align", e.Id)
	End If
	If e.Valign.Length > 0 And e.Valign <> "top" And e.Valign <> "middle" And e.Valign <> "bottom" Then
		mDiags.AddErrorAt("E-VAL-107", "element valign must be top, middle or bottom", path & "/valign", e.Id)
	End If

	If e.ElementType = "text" Then
		If e.ValueExpression.Length > 0 Then
			mDiags.AddErrorAt("E-VAL-097", "text element must not have a value expression", path & "/value", e.Id)
		End If
		If e.Text.Length = 0 Then
			mDiags.AddWarningAt("W-VAL-001", "text element is empty", path, e.Id)
		End If
	Else If e.ElementType = "field" Then
		If e.ValueExpression.Length = 0 Then
			mDiags.AddErrorAt("E-VAL-098", "field element has no value expression", path & "/value", e.Id)
		End If
		If e.Text.Length > 0 Then
			mDiags.AddErrorAt("E-VAL-099", "field element must not have static text", path & "/text", e.Id)
		End If
	Else If e.ElementType = "image" Then
		If e.Resource.Length = 0 Then
			mDiags.AddErrorAt("E-VAL-100", "image element has no resource", path & "/resource", e.Id)
		Else
			If SafeResource(e.Resource) = False Then
				mDiags.AddErrorAt("E-VAL-101", "image resource must be a relative path inside the template folder", path & "/resource", e.Id)
			Else If mBaseDir.Length > 0 Then
				If File.Exists(mBaseDir, e.Resource) = False Then
					mDiags.AddErrorAt("E-VAL-102", "missing image resource '" & e.Resource & "'", path & "/resource", e.Id)
				End If
			End If
		End If
		If e.Fit <> "contain" And e.Fit <> "stretch" And e.Fit <> "none" Then
			mDiags.AddErrorAt("E-VAL-103", "image fit must be contain, stretch or none", path & "/fit", e.Id)
		End If
	Else If e.ElementType = "line" Then
		If e.LineWidth < 0 Then
			mDiags.AddErrorAt("E-VAL-104", "line width must not be negative", path & "/width", e.Id)
		End If
	Else If e.ElementType = "rect" Then
		If e.Radius < 0 Then
			mDiags.AddErrorAt("E-VAL-105", "rect radius must not be negative", path & "/radius", e.Id)
		End If
	End If

	If e.Colour.Length > 0 And IsColour(e.Colour) = False Then
		mDiags.AddErrorAt("E-VAL-106", "invalid colour '" & e.Colour & "'", path & "/colour", e.Id)
	End If
	If e.FillColour.Length > 0 And IsColour(e.FillColour) = False Then
		mDiags.AddErrorAt("E-VAL-106", "invalid fill colour '" & e.FillColour & "'", path & "/fill", e.Id)
	End If

	If e.VisibleExpression.Length > 0 Then
		ValidateExpression(e.VisibleExpression, SectionDataSet, path & "/visible", e.Id)
	End If
	If e.ValueExpression.Length > 0 Then
		ValidateExpression(e.ValueExpression, SectionDataSet, path & "/value", e.Id)
	End If
End Sub

Private Sub SafeResource (Resource As String) As Boolean
	If Resource.Length = 0 Then Return False
	If Resource.SubString2(0, 1) = "/" Or Resource.SubString2(0, 1) = "\" Then Return False
	If Resource.IndexOf(":") >= 0 Then Return False
	If Resource.IndexOf("..") >= 0 Then Return False
	Return True
End Sub

Private Sub IsColour (Value As String) As Boolean
	If Value.Length <> 4 And Value.Length <> 7 Then Return False
	If Value.SubString2(0, 1) <> "#" Then Return False
	For i = 1 To Value.Length - 1
		Dim c As String = Value.SubString2(i, i + 1)
		Dim code As Int = Asc(c)
		Dim ok As Boolean = (code >= 48 And code <= 57) Or (code >= 65 And code <= 70) Or (code >= 97 And code <= 102)
		If ok = False Then Return False
	Next
	Return True
End Sub

'--------------------------------------------------------------- expressions

Private Sub ValidateExpression (Expression As String, SectionDataSet As String, Path As String, ElementId As String)
	Dim expressions As List = ReportExpressionRefs.Extract(Expression, mDiags, Path)
	For Each expr As String In expressions
		Dim ids As List = ReportExpressionRefs.Identifiers(expr, mDiags, Path)
		For Each raw As String In ids
			ValidateIdentifier(raw, SectionDataSet, Path, ElementId)
		Next
	Next
End Sub

Private Sub ValidateIdentifier (Raw As String, SectionDataSet As String, Path As String, ElementId As String)
	Dim name As String = Raw
	Dim low As String = name.ToLowerCase

	If low = "and" Or low = "or" Or low = "not" Or low = "true" Or low = "false" Or low = "if" Then Return
	If AllowedFunctions.IndexOf("|" & low & "|") >= 0 Then Return
	If low = "page.number" Or low = "page.count" Then Return

	If low.Length > 6 Then
		If low.SubString2(0, 6) = "param." Then
			Dim pname As String = name.SubString(6)
			If mParams.ContainsKey(pname) = False Then
				mDiags.AddErrorAt("E-EXPR-010", "unknown parameter '" & pname & "' in expression", Path, ElementId)
			End If
			Return
		End If
	End If

	Dim dot As Int = name.IndexOf(".")
	If dot > 0 Then
		Dim dsName As String = name.SubString2(0, dot)
		Dim rest As String = name.SubString(dot + 1)
		If mDataSets.ContainsKey(dsName) = False Then
			mDiags.AddErrorAt("E-EXPR-011", "unknown dataset '" & dsName & "' in expression", Path, ElementId)
			Return
		End If
		Dim ds As ReportDataSetDef = mDataSets.Get(dsName)
		If ds.FieldByName(rest) = Null And mAggs.ContainsKey(rest) = False Then
			mDiags.AddErrorAt("E-EXPR-012", "unknown field or aggregate '" & rest & "' in " & dsName, Path, ElementId)
		End If
		Return
	End If

	'Bare name: aggregate, then section field, then parameter. Ambiguity is an
	'error because the template must not silently pick one.
	Dim matches As Int = 0
	If mAggs.ContainsKey(name) Then matches = matches + 1
	If SectionDataSet.Length > 0 Then
		Dim sds As ReportDataSetDef = DataSetOrNull(SectionDataSet)
		If sds <> Null Then
			If sds.FieldByName(name) <> Null Then matches = matches + 1
		End If
	End If
	If mParams.ContainsKey(name) Then matches = matches + 1

	If matches = 0 Then
		mDiags.AddErrorAt("E-EXPR-013", "unknown identifier '" & name & "' in expression", Path, ElementId)
	Else If matches > 1 Then
		mDiags.AddErrorAt("E-EXPR-014", "ambiguous identifier '" & name & "' in expression", Path, ElementId)
	End If
End Sub
