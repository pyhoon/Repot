B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'HTML exporter for the render document. Pure B4X; no third-party
'dependency. Emits one absolutely positioned page per render page with
'print-friendly CSS page breaks.

Sub Class_Globals
	Public Diagnostics As ReportDiagnostics
	Private mDoc As ReportRenderDocument
End Sub

Public Sub Initialize (Diags As ReportDiagnostics)
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
End Sub

Public Sub Export (Doc As ReportRenderDocument, OutputPath As String) As Boolean
	mDoc = Doc
	Try
		Dim html As String = BuildHtml(Doc)
		#If B4A
		Dim fp As String = OutputPath
		Dim fn As String = OutputPath
		Dim i As Int = OutputPath.LastIndexOf("/")
		If i > -1 Then
			fp = OutputPath.SubString2(0, i)
			fn = OutputPath.SubString(i + 1)
		End If
		File.WriteString(fp, fn, html)
		#Else
		File.WriteString(File.GetFileParent(OutputPath), File.GetName(OutputPath), html)
		#End If		
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-HTML-001", "HTML export failed: " & LastException.Message, "")
		Return False
	End Try
End Sub

Public Sub ToHtml (Doc As ReportRenderDocument) As String
	Return BuildHtml(Doc)
End Sub

Private Sub BuildHtml (Doc As ReportRenderDocument) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("<!DOCTYPE html>").Append(CRLF)
	sb.Append("<html><head><meta charset=""utf-8"">")
	sb.Append("<meta name=""viewport"" content=""width=device-width, initial-scale=1"">")
	sb.Append("<title>Report</title>").Append(CRLF)
	sb.Append("<style>").Append(CRLF)
	sb.Append("body{margin:0;font-family:sans-serif;}").Append(CRLF)
	sb.Append(".page{position:relative;margin:0 auto;page-break-after:always;overflow:hidden;}").Append(CRLF)
	sb.Append(".op{position:absolute;white-space:pre;}").Append(CRLF)
	sb.Append("@media print{.page{page-break-after:always;}}").Append(CRLF)
	sb.Append("</style></head><body>").Append(CRLF)

	Dim i As Int
	For i = 0 To Doc.PageCount - 1
		Dim p As ReportRenderPage = Doc.PageAt(i + 1)
		sb.Append("<div class=""page"" style=""width:").Append(p.Width).Append("pt;height:").Append(p.Height).Append("pt;"">").Append(CRLF)
		Dim k As Int
		For k = 0 To p.Ops.Size - 1
			Dim op As ReportDrawOp = p.Ops.Get(k)
			sb.Append(OpHtml(op))
		Next
		sb.Append("</div>").Append(CRLF)
	Next
	sb.Append("</body></html>")
	Return sb.ToString
End Sub

Private Sub OpHtml (op As ReportDrawOp) As String
	Dim sb As StringBuilder
	sb.Initialize
	Select Case op.OpType
		Case "text"
			Dim style As String = "left:" & op.X & "pt;top:" & op.Y & "pt;width:" & op.Width & "pt;height:" & op.Height & "pt;"
			style = style & "font-family:" & op.FontName & ";font-size:" & op.FontSize & "pt;"
			If op.Bold Then style = style & "font-weight:bold;"
			If op.Italic Then style = style & "font-style:italic;"
			If op.Underline Then style = style & "text-decoration:underline;"
			If op.Colour.Length > 0 Then style = style & "color:" & op.Colour & ";"
			style = style & "text-align:" & op.Align & ";"
			sb.Append("<span class=""op"" style=""").Append(style).Append(""">").Append(HtmlEscape(op.Text)).Append("</span>").Append(CRLF)
		Case "image"
			Dim istyle As String = "left:" & op.X & "pt;top:" & op.Y & "pt;width:" & op.Width & "pt;height:" & op.Height & "pt;"
			sb.Append("<img class=""op"" style=""").Append(istyle).Append(""" src=""").Append(HtmlEscape(op.ResourcePath)).Append(""" alt="""" />").Append(CRLF)
		Case "line"
			Dim lstyle As String = "left:" & op.X & "pt;top:" & op.Y & "pt;width:" & (op.X2 - op.X) & "pt;height:0;border-top:" & op.LineWidth & "pt solid " & op.Colour & ";"
			sb.Append("<div class=""op"" style=""").Append(lstyle).Append("""></div>").Append(CRLF)
		Case "rect"
			Dim rstyle As String = "left:" & op.X & "pt;top:" & op.Y & "pt;width:" & op.Width & "pt;height:" & op.Height & "pt;"
			If op.FillColour.Length > 0 Then rstyle = rstyle & "background:" & op.FillColour & ";"
			If op.Colour.Length > 0 Then rstyle = rstyle & "border:" & op.LineWidth & "pt solid " & op.Colour & ";"
			sb.Append("<div class=""op"" style=""").Append(rstyle).Append("""></div>").Append(CRLF)
		Case "clip", "restore", "link"
			' no visual or handled separately
	End Select
	Return sb.ToString
End Sub

Private Sub HtmlEscape (s As String) As String
	Dim out As String = s
	out = out.Replace("&", "&amp;")
	out = out.Replace("<", "&lt;")
	out = out.Replace(">", "&gt;")
	out = out.Replace(Chr(34), "&quot;")
	Return out
End Sub
