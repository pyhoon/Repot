B4J=true
Group=Render
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
'Canonical JSON writer for the render document. The output is the golden
'format described in docs/render-document.md §7: fixed key order, page
'dimensions at four decimals, operation geometry at two decimals, empty
'optional strings and zero optional numbers omitted, no handles.

Sub Process_Globals

End Sub

Public Sub ToJson (Doc As ReportRenderDocument) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("{")
	sb.Append(Chr(34)).Append("version").Append(Chr(34)).Append(": ").Append(Doc.Version)
	sb.Append(", ").Append(Chr(34)).Append("pages").Append(Chr(34)).Append(": [")
	Dim i As Int
	For i = 0 To Doc.PageCount - 1
		If i > 0 Then sb.Append(", ")
		Dim p As ReportRenderPage = Doc.PageAt(i + 1)
		sb.Append(PageJson(p))
	Next
	sb.Append("]}")
	Return sb.ToString
End Sub

Private Sub PageJson (p As ReportRenderPage) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("{")
	sb.Append(Chr(34)).Append("index").Append(Chr(34)).Append(": ").Append(p.Index)
	sb.Append(", ").Append(Chr(34)).Append("width").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(p.Width, 4))
	sb.Append(", ").Append(Chr(34)).Append("height").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(p.Height, 4))
	sb.Append(", ").Append(Chr(34)).Append("ops").Append(Chr(34)).Append(": [")
	Dim i As Int
	For i = 0 To p.Ops.Size - 1
		If i > 0 Then sb.Append(", ")
		Dim op As ReportDrawOp = p.Ops.Get(i)
		sb.Append(OpJson(op))
	Next
	sb.Append("]")
	sb.Append(", ").Append(Chr(34)).Append("anchors").Append(Chr(34)).Append(": [")
	For i = 0 To p.Anchors.Size - 1
		If i > 0 Then sb.Append(", ")
		Dim a As ReportRenderAnchor = p.Anchors.Get(i)
		sb.Append("{")
		sb.Append(Chr(34)).Append("name").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(a.Name))
		sb.Append(", ").Append(Chr(34)).Append("x").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(a.X, 2))
		sb.Append(", ").Append(Chr(34)).Append("y").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(a.Y, 2))
		sb.Append("}")
	Next
	sb.Append("]}")
	Return sb.ToString
End Sub

Private Sub OpJson (op As ReportDrawOp) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("{")
	sb.Append(Chr(34)).Append("type").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.OpType))
	Select Case op.OpType
		Case "text"
			AppendGeom(sb, op)
			sb.Append(", ").Append(Chr(34)).Append("baseline").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Baseline, 2))
			sb.Append(", ").Append(Chr(34)).Append("text").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Text))
			sb.Append(", ").Append(Chr(34)).Append("font").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.FontName))
			sb.Append(", ").Append(Chr(34)).Append("size").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.FontSize, 2))
			sb.Append(", ").Append(Chr(34)).Append("bold").Append(Chr(34)).Append(": ").Append(BoolStr(op.Bold))
			sb.Append(", ").Append(Chr(34)).Append("italic").Append(Chr(34)).Append(": ").Append(BoolStr(op.Italic))
			sb.Append(", ").Append(Chr(34)).Append("underline").Append(Chr(34)).Append(": ").Append(BoolStr(op.Underline))
			If op.Colour.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("colour").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Colour))
			End If
			sb.Append(", ").Append(Chr(34)).Append("align").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Align))
		Case "image"
			AppendGeom(sb, op)
			sb.Append(", ").Append(Chr(34)).Append("resource").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.ResourcePath))
			If op.PixelWidth > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("pixelWidth").Append(Chr(34)).Append(": ").Append(op.PixelWidth)
			End If
			If op.PixelHeight > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("pixelHeight").Append(Chr(34)).Append(": ").Append(op.PixelHeight)
			End If
			If op.Dpi > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("dpi").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Dpi, 2))
			End If
			If op.Fit.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("fit").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Fit))
			End If
		Case "line"
			sb.Append(", ").Append(Chr(34)).Append("x").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.X, 2))
			sb.Append(", ").Append(Chr(34)).Append("y").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Y, 2))
			sb.Append(", ").Append(Chr(34)).Append("x2").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.X2, 2))
			sb.Append(", ").Append(Chr(34)).Append("y2").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Y2, 2))
			sb.Append(", ").Append(Chr(34)).Append("lineWidth").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.LineWidth, 2))
			If op.Colour.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("colour").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Colour))
			End If
			If op.Dash.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("dash").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Dash))
			End If
		Case "rect"
			AppendGeom(sb, op)
			sb.Append(", ").Append(Chr(34)).Append("lineWidth").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.LineWidth, 2))
			If op.Colour.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("colour").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Colour))
			End If
			If op.FillColour.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("fill").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.FillColour))
			End If
			If op.Radius > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("radius").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Radius, 2))
			End If
		Case "clip"
			AppendGeom(sb, op)
		Case "restore"
			' no fields
		Case "link"
			AppendGeom(sb, op)
			If op.Url.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("url").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.Url))
			End If
			If op.AnchorName.Length > 0 Then
				sb.Append(", ").Append(Chr(34)).Append("anchorName").Append(Chr(34)).Append(": ").Append(ReportJsonUtil.JsonQuote(op.AnchorName))
			End If
	End Select
	sb.Append("}")
	Return sb.ToString
End Sub

Private Sub AppendGeom (sb As StringBuilder, op As ReportDrawOp)
	sb.Append(", ").Append(Chr(34)).Append("x").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.X, 2))
	sb.Append(", ").Append(Chr(34)).Append("y").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Y, 2))
	sb.Append(", ").Append(Chr(34)).Append("width").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Width, 2))
	sb.Append(", ").Append(Chr(34)).Append("height").Append(Chr(34)).Append(": ").Append(ReportUnits.FormatNumber(op.Height, 2))
End Sub

Private Sub BoolStr (b As Boolean) As String
	If b Then Return "true"
	Return "false"
End Sub
