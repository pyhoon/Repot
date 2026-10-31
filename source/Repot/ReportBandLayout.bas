B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Band layout: style resolution, grid normalisation, text measurement,
'auto-grow and push-down. Pagination is deliberately not part of this
'class; it consumes the bands produced here.
Sub Class_Globals
	Public Diagnostics As ReportDiagnostics
	Public Measure As ReportB4JMeasure
	Private mCellWidth As Double
	Private mCellHeight As Double
	Private mGridReady As Boolean
End Sub

Public Sub Initialize (Diags As ReportDiagnostics, Measurement As ReportB4JMeasure)
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
	Measure = Measurement
	mCellWidth = 0
	mCellHeight = 0
	mGridReady = False
End Sub

'--------------------------------------------------------------- public

'Lays out one section into a band. ContentWidth and ContentHeight are the
'page content box in points; they drive grid cell sizes when the page
'uses column/row counts. Values supplies resolved text for field elements
'(keyed by element id); text elements use their own text.
Public Sub LayoutBand (Def As ReportDefinition, Section As ReportSection, ContentWidth As Double, ContentHeight As Double, Values As Map) As ReportBand
	Dim band As ReportBand
	band.Initialize
	band.Section = Section
	band.Width = ContentWidth
	band.MinHeight = Section.Height
	band.X = 0
	band.Y = 0
	If Values = Null Then
		Dim empty As Map
		empty.Initialize
		Values = empty
	End If

	PrepareGrid(Def.Page, ContentWidth, ContentHeight)

	' Children in document order; this is the paint order and the stable
	' tie-break for push-down.
	For Each e As ReportElement In Section.Elements
		Dim item As ReportLayoutElement
		item.Initialize
		item.Element = e
		item.DeclaredHeight = e.Height
		item.Height = e.Height
		item.Overflow = ResolveOverflow(Def, e)
		item.Style = ResolveStyle(Def, e)
		If Measure <> Null Then item.Font = Measure.ResolveStyle(item.Style)
		item.Content = ResolveContent(e, Values)
		item.Align = ResolveAlign(Def, e)
		item.Valign = ResolveValign(Def, e)
		NormalizeBounds(e, item)
		band.Elements.Add(item)
	Next

	MeasureAndGrow(band, Def)
	ApplyPushDown(band.Elements)
	ComputeHeight(band)
	Return band
End Sub

'--------------------------------------------------------------- grid

Private Sub PrepareGrid (Page As ReportPageSetup, ContentWidth As Double, ContentHeight As Double)
	mGridReady = True
	If Page.CellWidth > 0 Then
		mCellWidth = Page.CellWidth
	Else If Page.GridColumns > 0 Then
		mCellWidth = ContentWidth / Page.GridColumns
	Else
		mCellWidth = 0
	End If
	If Page.CellHeight > 0 Then
		mCellHeight = Page.CellHeight
	Else If Page.GridRows > 0 Then
		mCellHeight = ContentHeight / Page.GridRows
	Else
		mCellHeight = 0
	End If
End Sub

Private Sub NormalizeBounds (e As ReportElement, item As ReportLayoutElement)
	If e.UseCell Then
		item.X = e.CellCol * mCellWidth
		item.Y = e.CellRow * mCellHeight
		item.Width = e.CellColSpan * mCellWidth
		item.Height = e.CellRowSpan * mCellHeight
		item.DeclaredHeight = item.Height
	Else
		item.X = e.X
		item.Y = e.Y
		item.Width = e.Width
		item.Height = e.Height
		item.DeclaredHeight = e.Height
	End If
End Sub

'--------------------------------------------------------------- style

Private Sub ResolveStyle (Def As ReportDefinition, e As ReportElement) As ReportTextStyle
	Dim ts As ReportTextStyle
	ts.Initialize

	Dim st As ReportStyle = Def.StyleByName(e.StyleName)
	Dim fd As ReportFontDef = Null
	If st <> Null Then
		fd = Def.FontByName(st.FontName)
	End If

	If fd <> Null Then
		For Each fam As String In fd.Family
			ts.Family.Add(fam)
		Next
		If st.Size > 0 Then
			ts.Size = st.Size
		Else If fd.Size > 0 Then
			ts.Size = fd.Size
		Else
			ts.Size = 10
		End If
	Else If st <> Null Then
		If st.Size > 0 Then ts.Size = st.Size Else ts.Size = 10
	End If

	If st <> Null Then
		ts.Bold = st.Bold
		ts.Italic = st.Italic
		ts.Underline = st.Underline
		If st.Colour.Length > 0 Then ts.Colour = st.Colour
		If st.LineSpacing > 0 Then ts.LineSpacing = st.LineSpacing Else ts.LineSpacing = 1.2
	End If
	If ts.Size <= 0 Then ts.Size = 10
	If ts.Family.Size = 0 Then ts.SetFamily("Dialog")
	Return ts
End Sub

Private Sub ResolveOverflow (Def As ReportDefinition, e As ReportElement) As String
	Dim st As ReportStyle = Def.StyleByName(e.StyleName)
	If st <> Null And st.Overflow.Length > 0 Then Return st.Overflow
	Select Case e.ElementType
		Case "text", "field"
			Return "grow"
		Case Else
			Return "clip"
	End Select
End Sub

Private Sub ResolveAlign (Def As ReportDefinition, e As ReportElement) As String
	If e.Align.Length > 0 Then Return e.Align
	Dim st As ReportStyle = Def.StyleByName(e.StyleName)
	If st <> Null And st.Align.Length > 0 Then Return st.Align
	Return "left"
End Sub

Private Sub ResolveValign (Def As ReportDefinition, e As ReportElement) As String
	If e.Valign.Length > 0 Then Return e.Valign
	Dim st As ReportStyle = Def.StyleByName(e.StyleName)
	If st <> Null And st.Valign.Length > 0 Then Return st.Valign
	Return "top"
End Sub

Private Sub ResolveContent (e As ReportElement, Values As Map) As String
	Select Case e.ElementType
		Case "text"
			Return e.Text
		Case "field"
			If Values.ContainsKey(e.Id) Then Return Values.Get(e.Id)
			Return e.ValueExpression
		Case Else
			Return ""
	End Select
End Sub

'--------------------------------------------------------------- measurement

Private Sub IsTextElement (e As ReportElement) As Boolean
	Return e.ElementType = "text" Or e.ElementType = "field"
End Sub

Private Sub MeasureAndGrow (band As ReportBand, Def As ReportDefinition)
	If Measure = Null Then Return
	For Each item As ReportLayoutElement In band.Elements
		If IsTextElement(item.Element) = False Then Continue
		Dim lh As Double = Measure.LineHeight(item.Style)
		If lh <= 0 Then lh = item.Style.Size * item.Style.LineSpacing
		If item.Style.LineSpacing <= 0 Then lh = item.Style.Size * 1.2
		Select Case item.Overflow
			Case "grow"
				Dim m As ReportTextMetrics = Measure.MeasureBlock(item.Content, item.Style, item.Width)
				item.Lines = m.Lines
				item.LineWidths = m.Widths
				item.MeasuredHeight = m.Height
				If m.Height > item.Height Then
					item.GrowBy = m.Height - item.Height
					item.Height = m.Height
				Else
					item.GrowBy = 0
				End If
			Case "clip"
				Dim m2 As ReportTextMetrics = Measure.MeasureBlock(item.Content, item.Style, item.Width)
				item.MeasuredHeight = m2.Height
				Dim maxLines As Int = 0
				If lh > 0 Then maxLines = Floor(item.Height / lh)
				If maxLines < 1 Then maxLines = 1
				Dim taken As Int = 0
				Dim i As Int = 0
				Do While i < m2.Lines.Size And taken < maxLines
					item.Lines.Add(m2.Lines.Get(i))
					item.LineWidths.Add(m2.Widths.Get(i))
					taken = taken + 1
					i = i + 1
				Loop
				item.GrowBy = 0
			Case "ellipsis"
				item.Lines.Initialize
				item.LineWidths.Initialize
				Dim fullW As Double = Measure.MeasureLine(item.Content, item.Style)
				If fullW <= item.Width Or item.Width <= 0 Then
					item.Lines.Add(item.Content)
					item.LineWidths.Add(fullW)
				Else
					Dim ell As String = "…"
					Dim candidate As String = item.Content
					Do While candidate.Length > 0
						candidate = candidate.SubString2(0, candidate.Length - 1)
						Dim w As Double = Measure.MeasureLine(candidate & ell, item.Style)
						If w <= item.Width Then Exit
					Loop
					If candidate.Length = 0 Then
						item.Lines.Add(ell)
						item.LineWidths.Add(Measure.MeasureLine(ell, item.Style))
					Else
						item.Lines.Add(candidate & ell)
						item.LineWidths.Add(Measure.MeasureLine(candidate & ell, item.Style))
					End If
				End If
				item.MeasuredHeight = lh
				item.GrowBy = 0
			Case Else
				item.GrowBy = 0
		End Select
	Next
End Sub

'--------------------------------------------------------------- push-down

Private Sub ApplyPushDown (Items As List)
	Dim n As Int = Items.Size
	If n <= 1 Then Return

	' Stable order by current Y, then X, then document order. Items are
	' already in document order, so a stable sort by (Y, X) keeps that
	' tie-break.
	Dim order As List
	order.Initialize
	Dim i As Int
	For i = 0 To n - 1
		order.Add(i)
	Next

	' Insertion sort, stable.
	Dim a As Int
	For a = 1 To n - 1
		Dim keyIdx As Int = order.Get(a)
		Dim keyItem As ReportLayoutElement = Items.Get(keyIdx)
		Dim b As Int = a - 1
		Do While b >= 0
			Dim otherIdx As Int = order.Get(b)
			Dim otherItem As ReportLayoutElement = Items.Get(otherIdx)
			If LessThanOrEqual(otherItem, keyItem) Then Exit
			order.Set(b + 1, otherIdx)
			b = b - 1
		Loop
		order.Set(b + 1, keyIdx)
	Next

	For a = 0 To n - 1
		Dim ia As Int = order.Get(a)
		Dim itemA As ReportLayoutElement = Items.Get(ia)
		If itemA.GrowBy <= 0 Then Continue
		Dim delta As Double = itemA.GrowBy
		Dim threshold As Double = itemA.Y + itemA.DeclaredHeight
		Dim bb As Int
		For bb = a + 1 To n - 1
			Dim ib As Int = order.Get(bb)
			Dim itemB As ReportLayoutElement = Items.Get(ib)
			If itemB.Y >= threshold - 0.000001 Then
				itemB.Y = itemB.Y + delta
			End If
		Next
	Next
End Sub

Private Sub LessThanOrEqual (a As ReportLayoutElement, b As ReportLayoutElement) As Boolean
	If a.Y < b.Y - 0.000001 Then Return True
	If a.Y > b.Y + 0.000001 Then Return False
	If a.X < b.X - 0.000001 Then Return True
	If a.X > b.X + 0.000001 Then Return False
	Return True
End Sub

'--------------------------------------------------------------- height

Private Sub ComputeHeight (band As ReportBand)
	Dim maxBottom As Double = band.MinHeight
	For Each item As ReportLayoutElement In band.Elements
		Dim bottom As Double = item.Y + item.Height
		If bottom > maxBottom Then maxBottom = bottom
	Next
	band.Height = maxBottom
	If band.Height < band.MinHeight Then band.Height = band.MinHeight
End Sub
