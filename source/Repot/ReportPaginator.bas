B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Pagination and render-document emission for non-grouped reports.
'
'Two passes are always run: pass 1 records the page count, pass 2 emits
'operations with the final count substituted. Field values are resolved
'with a deliberately small resolver covering the cases the fixtures need
'(param.X, Dataset.Field, bare field/aggregate, page.number/page.count);
'full expression evaluation remains M6 work.

Sub Class_Globals
	Public Definition As ReportDefinition
	Public Binder As ReportDataBinder
	Public Measure As ReportB4JMeasure
	Public Diagnostics As ReportDiagnostics

	Private mDoc As ReportRenderDocument
	Private mBandLayout As ReportBandLayout
	Private mEmit As Boolean
	Private mPageNo As Int
	Private mPageCount As Int

	Private mContentWidth As Double
	Private mContentHeight As Double
	Private mMarginLeft As Double
	Private mMarginTop As Double
	Private mMarginBottom As Double
	Private mPageWidth As Double
	Private mPageHeight As Double
	Private mPageHeaderHeight As Double
	Private mPageFooterHeight As Double
	Private mCurrentPage As ReportRenderPage
	Private mCurrentY As Double

	Private mDetailSection As ReportSection
	Private mDetailDataSetName As String
	Private mHasReportHeader As Boolean
	Private mHasPageHeader As Boolean
	Private mHasReportFooter As Boolean
	Private mHasPageFooter As Boolean

	Private mCurrentRecord As Map
	Private mCurrentDataSet As String
	Private mAggregates As Map
End Sub

Public Sub Initialize (Def As ReportDefinition, B As ReportDataBinder, M As ReportB4JMeasure, Diags As ReportDiagnostics)
	Definition = Def
	Binder = B
	Measure = M
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
	mBandLayout.Initialize(Diagnostics, Measure)
	mAggregates.Initialize
	ComputeAggregates()

	mContentWidth = Def.Page.ContentWidth
	mContentHeight = Def.Page.ContentHeight
	mMarginLeft = Def.Page.MarginLeft
	mMarginTop = Def.Page.MarginTop
	mMarginBottom = Def.Page.MarginBottom
	mPageWidth = Def.Page.Width
	mPageHeight = Def.Page.Height

	mDetailSection = Def.SectionByType("Detail")
	If mDetailSection <> Null Then mDetailDataSetName = mDetailSection.DataSet
	mHasReportHeader = (Def.SectionByType("ReportHeader") <> Null)
	mHasPageHeader = (Def.SectionByType("PageHeader") <> Null)
	mHasReportFooter = (Def.SectionByType("ReportFooter") <> Null)
	mHasPageFooter = (Def.SectionByType("PageFooter") <> Null)

	If mHasPageHeader Then
		Dim ph As ReportSection = Def.SectionByType("PageHeader")
		mPageHeaderHeight = ph.Height
	Else
		mPageHeaderHeight = 0
	End If
	If mHasPageFooter Then
		Dim pf As ReportSection = Def.SectionByType("PageFooter")
		mPageFooterHeight = pf.Height
	Else
		mPageFooterHeight = 0
	End If
End Sub

Public Sub Render As ReportRenderDocument
	' pass 1: count pages
	mEmit = False
	mDoc = Null
	mPageNo = 0
	RunPass
	mPageCount = mPageNo
	If mPageCount < 1 Then mPageCount = 1

	' pass 2: emit
	mEmit = True
	Dim newDoc As ReportRenderDocument
	newDoc.Initialize
	mDoc = newDoc
	mPageNo = 0
	RunPass
	Return mDoc
End Sub

'--------------------------------------------------------------- pass

Private Sub RunPass
	Dim firstPage As Boolean = True
	NewPage
	' page 1: report header then page header
	If firstPage And mHasReportHeader Then
		Dim rh As ReportSection = Definition.SectionByType("ReportHeader")
		Dim rhBand As ReportBand = mBandLayout.LayoutBand(Definition, rh, mContentWidth, mContentHeight, BuildValues(rh, Null))
		PlaceBand(rhBand, mCurrentY)
		mCurrentY = mCurrentY + rhBand.Height
	End If
	If mHasPageHeader Then
		Dim ph As ReportSection = Definition.SectionByType("PageHeader")
		Dim phBand As ReportBand = mBandLayout.LayoutBand(Definition, ph, mContentWidth, mContentHeight, BuildValues(ph, Null))
		PlaceBand(phBand, mCurrentY)
		mCurrentY = mCurrentY + phBand.Height
	End If

	' detail loop
	If mDetailSection <> Null Then
		Dim ds As ReportDataSet = Binder.GetDataSet(mDetailDataSetName)
		Dim records As List
		If ds <> Null Then records = ds.Records Else records = Null
		If records <> Null Then
			For Each rec As Map In records
				mCurrentRecord = rec
				mCurrentDataSet = mDetailDataSetName
				Dim dband As ReportBand = mBandLayout.LayoutBand(Definition, mDetailSection, mContentWidth, mContentHeight, BuildValues(mDetailSection, rec))
				Dim contentBottom As Double = mPageHeight - mMarginBottom - mPageFooterHeight
				If mCurrentY + dband.Height > contentBottom + 0.000001 Then
					FinishPage
					NewPage
					' page header on new page
					If mHasPageHeader Then
						Dim ph2 As ReportSection = Definition.SectionByType("PageHeader")
						Dim phBand2 As ReportBand = mBandLayout.LayoutBand(Definition, ph2, mContentWidth, mContentHeight, BuildValues(ph2, Null))
						PlaceBand(phBand2, mCurrentY)
						mCurrentY = mCurrentY + phBand2.Height
					End If
				End If
				PlaceBand(dband, mCurrentY)
				mCurrentY = mCurrentY + dband.Height
			Next
		End If
	End If

	' report footer
	If mHasReportFooter Then
		mCurrentRecord = Null
		mCurrentDataSet = ""
		Dim rf As ReportSection = Definition.SectionByType("ReportFooter")
		Dim rfBand As ReportBand = mBandLayout.LayoutBand(Definition, rf, mContentWidth, mContentHeight, BuildValues(rf, Null))
		Dim contentBottom2 As Double = mPageHeight - mMarginBottom - mPageFooterHeight
		If mCurrentY + rfBand.Height > contentBottom2 + 0.000001 Then
			FinishPage
			NewPage
			If mHasPageHeader Then
				Dim ph3 As ReportSection = Definition.SectionByType("PageHeader")
				Dim phBand3 As ReportBand = mBandLayout.LayoutBand(Definition, ph3, mContentWidth, mContentHeight, BuildValues(ph3, Null))
				PlaceBand(phBand3, mCurrentY)
				mCurrentY = mCurrentY + phBand3.Height
			End If
		End If
		PlaceBand(rfBand, mCurrentY)
		mCurrentY = mCurrentY + rfBand.Height
	End If

	FinishPage
End Sub

Private Sub NewPage
	mPageNo = mPageNo + 1
	If mEmit Then
		mCurrentPage = mDoc.AddPage(mPageWidth, mPageHeight)
	End If
	mCurrentY = mMarginTop
End Sub

Private Sub FinishPage
	If mHasPageFooter Then
		Dim pf As ReportSection = Definition.SectionByType("PageFooter")
		Dim vals As Map = BuildValues(pf, Null)
		Dim pfBand As ReportBand = mBandLayout.LayoutBand(Definition, pf, mContentWidth, mContentHeight, vals)
		Dim y As Double = mPageHeight - mMarginBottom - mPageFooterHeight
		PlaceBand(pfBand, y)
	End If
End Sub

Private Sub PlaceBand (band As ReportBand, y As Double)
	' item.Y is relative to the band; make it absolute on the page.
	For Each pe As ReportLayoutElement In band.Elements
		pe.Y = pe.Y + y
	Next
	band.Y = y
	If mEmit Then
		EmitBand(band)
	End If
End Sub
'--------------------------------------------------------------- values

Private Sub BuildValues (sec As ReportSection, rec As Map) As Map
	Dim vals As Map
	vals.Initialize
	If sec = Null Then Return vals
	For Each el As ReportElement In sec.Elements
		If el.ElementType = "field" Then
			Dim raw As Object = ResolveRaw(el.ValueExpression)
			Dim st As ReportStyle = Definition.StyleByName(el.StyleName)
			Dim formatted As String = FormatValue(raw, el, st)
			vals.Put(el.Id, formatted)
		End If
	Next
	Return vals
End Sub

Private Sub ResolveRaw (Expr As String) As Object
	Dim t As String = Expr.Trim
	If t.IndexOf("{") < 0 Then Return t
	' Single brace pair covering the whole expression: resolve the inner
	' name to a typed value so formatting can be applied.
	If t.StartsWith("{") And t.EndsWith("}") Then
		Dim inner As String = t.SubString2(1, t.Length - 1).Trim
		If inner.IndexOf("{") < 0 And inner.IndexOf("}") < 0 Then
			Return ResolveInner(inner)
		End If
	End If
	' Mixed literal text and braces: interpolate.
	Return Interpolate(t)
End Sub

Private Sub ResolveInner (Expr As String) As Object
	Dim inner As String = Expr.Trim
	If inner.StartsWith("{") Then inner = inner.SubString(1)
	If inner.EndsWith("}") Then inner = inner.SubString2(0, inner.Length - 1)
	inner = inner.Trim
	If inner.Length = 0 Then Return ""

	Dim parts As List = SplitDots(inner)
	If parts.Size = 0 Then Return ""

	Dim first As String = parts.Get(0)
	If first = "param" And parts.Size >= 2 Then
		Return Binder.ParameterValue(parts.Get(1))
	End If
	If first = "page" And parts.Size >= 2 Then
		If parts.Get(1) = "number" Then Return mPageNo
		If parts.Get(1) = "count" Then Return mPageCount
	End If

	Dim dsDef As ReportDataSetDef = Definition.DataSetByName(first)
	If dsDef <> Null And parts.Size >= 2 Then
		Dim field As String = parts.Get(1)
		If dsDef.Kind = "single" Then
			Dim ds As ReportDataSet = Binder.GetDataSet(first)
			If ds <> Null Then
				If ds.SingleRecord.IsInitialized Then
					If ds.SingleRecord.ContainsKey(field) Then Return ds.SingleRecord.Get(field)
				End If
			End If
		Else
			If first = mCurrentDataSet And mCurrentRecord.IsInitialized Then
				If mCurrentRecord.ContainsKey(field) Then Return mCurrentRecord.Get(field)
			End If
			If mAggregates.ContainsKey(field) Then Return mAggregates.Get(field)
		End If
	End If

	If mAggregates.ContainsKey(first) Then Return mAggregates.Get(first)
	If mCurrentRecord.IsInitialized Then
		If mCurrentRecord.ContainsKey(first) Then Return mCurrentRecord.Get(first)
	End If
	Return Binder.ParameterValue(first)
End Sub

Private Sub Interpolate (s As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Dim depth As Int = 0
	Dim start As Int = -1
	Dim i As Int
	For i = 0 To s.Length - 1
		Dim c As String = s.SubString2(i, i + 1)
		If c = "{" Then
			If depth = 0 Then start = i + 1
			depth = depth + 1
		Else If c = "}" Then
			depth = depth - 1
			If depth = 0 And start >= 0 Then
				Dim inner As String = s.SubString2(start, i)
				Dim raw As Object = ResolveInner(inner)
				sb.Append(RawToString(raw))
				start = -1
			End If
		Else
			If depth = 0 Then sb.Append(c)
		End If
	Next
	Return sb.ToString
End Sub

Private Sub RawToString (v As Object) As String
	If v = Null Then Return ""
	Return v
End Sub

Private Sub SplitDots (s As String) As List
	Dim out As List
	out.Initialize
	Dim cur As StringBuilder
	cur.Initialize
	Dim i As Int
	For i = 0 To s.Length - 1
		Dim c As String = s.SubString2(i, i + 1)
		If c = "." Then
			out.Add(cur.ToString)
			cur.Initialize
		Else
			cur.Append(c)
		End If
	Next
	If cur.Length > 0 Then out.Add(cur.ToString)
	Return out
End Sub

'--------------------------------------------------------------- aggregates

Private Sub ComputeAggregates
	mAggregates.Initialize
	For Each dsName As String In Definition.DataSets.Keys
		Dim dsDef As ReportDataSetDef = Definition.DataSetByName(dsName)
		Dim ds As ReportDataSet = Binder.GetDataSet(dsName)
		If ds = Null Then Continue
		If dsDef.Aggregates = Null Then Continue
		For Each agg As ReportAggregateDef In dsDef.Aggregates
			Dim v As Object = ComputeAggregate(agg, ds)
			mAggregates.Put(agg.Name, v)
		Next
	Next
End Sub

Private Sub ComputeAggregate (agg As ReportAggregateDef, ds As ReportDataSet) As Object
	Select Case agg.FunctionName
		Case "count"
			Return ds.Records.Size
		Case "sum"
			Dim s As Double = 0
			For Each r As Map In ds.Records
				If r.ContainsKey(agg.FieldName) Then
					Dim d As Double = 0
					If IsNumber(r.Get(agg.FieldName)) Then d = r.Get(agg.FieldName)
					s = s + d
				End If
			Next
			Return s
		Case "avg"
			Dim s2 As Double = 0
			Dim n As Int = ds.Records.Size
			For Each r2 As Map In ds.Records
				If r2.ContainsKey(agg.FieldName) Then
					Dim d2 As Double = 0
					If IsNumber(r2.Get(agg.FieldName)) Then d2 = r2.Get(agg.FieldName)
					s2 = s2 + d2
				End If
			Next
			If n > 0 Then Return s2 / n Else Return 0
		Case "min"
			Dim have As Boolean = False
			Dim m As Double = 0
			For Each r3 As Map In ds.Records
				If r3.ContainsKey(agg.FieldName) Then
					If IsNumber(r3.Get(agg.FieldName)) Then
						Dim v As Double = r3.Get(agg.FieldName)
						If have = False Or v < m Then
							m = v
							have = True
						End If
					End If
				End If
			Next
			If have Then Return m Else Return 0
		Case "max"
			Dim have2 As Boolean = False
			Dim m2 As Double = 0
			For Each r4 As Map In ds.Records
				If r4.ContainsKey(agg.FieldName) Then
					If IsNumber(r4.Get(agg.FieldName)) Then
						Dim v2 As Double = r4.Get(agg.FieldName)
						If have2 = False Or v2 > m2 Then
							m2 = v2
							have2 = True
						End If
					End If
				End If
			Next
			If have2 Then Return m2 Else Return 0
	End Select
	Return 0
End Sub

'--------------------------------------------------------------- formatting

Private Sub FormatValue (Raw As Object, El As ReportElement, St As ReportStyle) As String
	Dim fmt As Map = El.FormatMap
	If fmt = Null Or fmt.Size = 0 Then
		If St <> Null Then fmt = St.FormatMap
	End If
	If fmt = Null Or fmt.Size = 0 Then
		If Raw = Null Then Return ""
		Return Raw
	End If

	Dim typ As String = ""
	If fmt.ContainsKey("type") Then typ = fmt.Get("type")

	If typ = "number" Then
		Dim decimals As Int = 0
		If fmt.ContainsKey("decimals") Then decimals = fmt.Get("decimals")
		Dim grouping As Boolean = False
		If fmt.ContainsKey("grouping") Then grouping = fmt.Get("grouping")
		Dim prefix As String = ""
		If fmt.ContainsKey("prefix") Then prefix = fmt.Get("prefix")
		Dim suffix As String = ""
		If fmt.ContainsKey("suffix") Then suffix = fmt.Get("suffix")
		Dim d As Double = 0
		If IsNumber(Raw) Then d = Raw
		Dim s As String = ReportUnits.FormatNumber(d, decimals)
		If grouping Then s = AddGrouping(s)
		Return prefix & s & suffix
	Else If typ = "date" Then
		Dim pattern As String = "yyyy-MM-dd"
		If fmt.ContainsKey("pattern") Then pattern = fmt.Get("pattern")
		If Raw = Null Then Return ""
		If (Raw Is String) Then Return Raw
		If IsNumber(Raw) Then
			Dim ticks As Long = Raw
			Return FormatDate(ticks, pattern)
		End If
		Return Raw
	Else If typ = "boolean" Then
		Dim trueText As String = "true"
		Dim falseText As String = "false"
		If fmt.ContainsKey("trueText") Then trueText = fmt.Get("trueText")
		If fmt.ContainsKey("falseText") Then falseText = fmt.Get("falseText")
		If Raw Is Boolean Then
			If Raw Then Return trueText Else Return falseText
		End If
		Return Raw
	Else If typ = "text" Then
		If Raw = Null Then Return ""
		Return Raw
	End If
	If Raw = Null Then Return ""
	Return Raw
End Sub

Private Sub AddGrouping (s As String) As String
	Dim dot As Int = s.IndexOf(".")
	Dim intPart As String
	Dim fracPart As String
	If dot >= 0 Then
		intPart = s.SubString2(0, dot)
		fracPart = s.SubString(dot)
	Else
		intPart = s
		fracPart = ""
	End If
	Dim out As StringBuilder
	out.Initialize
	Dim i As Int = intPart.Length - 1
	Dim count As Int = 0
	Do While i >= 0
		If count > 0 And count Mod 3 = 0 Then out.Insert(0, ",")
		out.Insert(0, intPart.SubString2(i, i + 1))
		count = count + 1
		i = i - 1
	Loop
	Return out.ToString & fracPart
End Sub

Private Sub FormatDate (ticks As Long, pattern As String) As String
	Dim y As Int = DateTime.GetYear(ticks)
	Dim mo As Int = DateTime.GetMonth(ticks)
	Dim da As Int = DateTime.GetDayOfMonth(ticks)
	Dim h As Int = DateTime.GetHour(ticks)
	Dim mi As Int = DateTime.GetMinute(ticks)
	Dim se As Int = DateTime.GetSecond(ticks)
	Dim out As String = pattern
	out = out.Replace("yyyy", Pad4(y))
	out = out.Replace("MM", Pad2(mo))
	out = out.Replace("dd", Pad2(da))
	out = out.Replace("HH", Pad2(h))
	out = out.Replace("mm", Pad2(mi))
	out = out.Replace("ss", Pad2(se))
	Return out
End Sub

Private Sub Pad2 (n As Int) As String
	Dim s As String = n
	If s.Length < 2 Then s = "0" & s
	Return s
End Sub

Private Sub Pad4 (n As Int) As String
	Dim s As String = n
	Do While s.Length < 4
		s = "0" & s
	Loop
	Return s
End Sub
Private Sub EmitBand (band As ReportBand)
	For Each item As ReportLayoutElement In band.Elements
		Dim x As Double = mMarginLeft + item.X
		Dim y As Double = item.Y
		Dim el As ReportElement = item.Element
		Select Case el.ElementType
			Case "text"
				EmitTextItem(item, x, y)
			Case "field"
				EmitTextItem(item, x, y)
			Case "image"
				Dim resPath As String = el.Resource
				If Definition.SourceDir.Length > 0 Then resPath = Definition.SourceDir & "/" & resPath
				Dim img As ReportImage = Measure.LoadImage(resPath, 0)
				mCurrentPage.AddImage(x, y, item.Width, item.Height, el.Resource, img.PixelWidth, img.PixelHeight, el.Dpi, el.Fit, img.Handle)
			Case "line"
				mCurrentPage.AddLine(x, y, x + item.Width, y + item.Height, el.LineWidth, el.Colour, el.Dash)
			Case "rect"
				mCurrentPage.AddRect(x, y, item.Width, item.Height, el.LineWidth, el.Colour, el.FillColour, el.Radius)
		End Select
	Next
End Sub

Private Sub EmitTextItem (item As ReportLayoutElement, x As Double, y As Double)
	Dim lh As Double = item.Style.LineSpacing * item.Style.Size
	If lh <= 0 Then lh = item.Style.Size * 1.2
	Dim lines As List = item.Lines
	If lines.Size = 0 Then
		lines.Initialize
		lines.Add(item.Content)
	End If
	Dim i As Int
	For i = 0 To lines.Size - 1
		Dim lineY As Double = y + i * lh
		Dim txt As String = lines.Get(i)
		mCurrentPage.AddText(x, lineY, item.Width, lh, item.Font.Ascent, txt, item.Font.Family, item.Font.Size, item.Font.Bold, item.Font.Italic, item.Style.Underline, item.Style.Colour, item.Align)
	Next
End Sub
