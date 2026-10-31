B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Data exporters (CSV, JSON, XML) for the processed data model. They do
'not use the render document; they consume the binder directly.

Sub Class_Globals
	Public Diagnostics As ReportDiagnostics
	Private mDef As ReportDefinition
	Private mBinder As ReportDataBinder
End Sub

Public Sub Initialize (Def As ReportDefinition, B As ReportDataBinder, Diags As ReportDiagnostics)
	mDef = Def
	mBinder = B
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
End Sub

Public Sub ExportCsv (DataSetName As String, OutputPath As String) As Boolean
	Dim ds As ReportDataSet = mBinder.GetDataSet(DataSetName)
	If ds = Null Then
		Diagnostics.AddError("E-DATA-010", "dataset '" & DataSetName & "' was not supplied", "")
		Return False
	End If
	Try
		Dim sb As StringBuilder
		sb.Initialize
		' header
		Dim fields As List = ds.Definition.Fields
		Dim i As Int
		For i = 0 To fields.Size - 1
			If i > 0 Then sb.Append(",")
			Dim f As ReportFieldDef = fields.Get(i)
			sb.Append(CsvQuote(f.Name))
		Next
		sb.Append(CRLF)
		For Each rec As Map In ds.Records
			For i = 0 To fields.Size - 1
				If i > 0 Then sb.Append(",")
				Dim f2 As ReportFieldDef = fields.Get(i)
				Dim v As Object = rec.Get(f2.Name)
				sb.Append(CsvValue(v))
			Next
			sb.Append(CRLF)
		Next
		File.WriteString(File.GetFileParent(OutputPath), File.GetName(OutputPath), sb.ToString)
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-IO-001", "CSV export failed: " & LastException.Message, "")
		Return False
	End Try
End Sub

Public Sub ExportJson (DataSetName As String, OutputPath As String) As Boolean
	Dim ds As ReportDataSet = mBinder.GetDataSet(DataSetName)
	If ds = Null Then
		Diagnostics.AddError("E-DATA-010", "dataset '" & DataSetName & "' was not supplied", "")
		Return False
	End If
	Try
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append("[")
		Dim i As Int
		For i = 0 To ds.Records.Size - 1
			If i > 0 Then sb.Append(",")
			Dim rec As Map = ds.Records.Get(i)
			sb.Append("{")
			Dim fields As List = ds.Definition.Fields
			Dim j As Int
			For j = 0 To fields.Size - 1
				If j > 0 Then sb.Append(",")
				Dim f As ReportFieldDef = fields.Get(j)
				sb.Append(ReportJsonUtil.JsonQuote(f.Name)).Append(":")
				sb.Append(JsonValue(rec.Get(f.Name)))
			Next
			sb.Append("}")
		Next
		sb.Append("]")
		File.WriteString(File.GetFileParent(OutputPath), File.GetName(OutputPath), sb.ToString)
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-IO-001", "JSON export failed: " & LastException.Message, "")
		Return False
	End Try
End Sub

Public Sub ExportXml (DataSetName As String, OutputPath As String, RootName As String) As Boolean
	Dim ds As ReportDataSet = mBinder.GetDataSet(DataSetName)
	If ds = Null Then
		Diagnostics.AddError("E-DATA-010", "dataset '" & DataSetName & "' was not supplied", "")
		Return False
	End If
	If RootName.Length = 0 Then RootName = "rows"
	Try
		Dim sb As StringBuilder
		sb.Initialize
		sb.Append("<?xml version=""1.0"" encoding=""UTF-8""?>").Append(CRLF)
		sb.Append("<").Append(RootName).Append(">").Append(CRLF)
		For Each rec As Map In ds.Records
			sb.Append("  <row>").Append(CRLF)
			For Each f As ReportFieldDef In ds.Definition.Fields
				Dim v As Object = rec.Get(f.Name)
				sb.Append("    <").Append(f.Name).Append(">")
				sb.Append(XmlEscape(ValueToString(v)))
				sb.Append("</").Append(f.Name).Append(">").Append(CRLF)
			Next
			sb.Append("  </row>").Append(CRLF)
		Next
		sb.Append("</").Append(RootName).Append(">").Append(CRLF)
		File.WriteString(File.GetFileParent(OutputPath), File.GetName(OutputPath), sb.ToString)
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-IO-001", "XML export failed: " & LastException.Message, "")
		Return False
	End Try
End Sub

Private Sub CsvQuote (s As String) As String
	Return Chr(34) & s.Replace(Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Sub

Private Sub CsvValue (v As Object) As String
	If v = Null Then Return ""
	If v Is String Then Return CsvQuote(v)
	If v Is Boolean Then
		If v Then Return "true" Else Return "false"
	End If
	Return v
End Sub

Private Sub JsonValue (v As Object) As String
	If v = Null Then Return "null"
	If v Is String Then Return ReportJsonUtil.JsonQuote(v)
	If v Is Boolean Then
		If v Then Return "true" Else Return "false"
	End If
	If IsNumber(v) Then Return v
	Return ReportJsonUtil.JsonQuote(v)
End Sub

Private Sub ValueToString (v As Object) As String
	If v = Null Then Return ""
	Return v
End Sub

Private Sub XmlEscape (s As String) As String
	Dim out As String = s
	out = out.Replace("&", "&amp;")
	out = out.Replace("<", "&lt;")
	out = out.Replace(">", "&gt;")
	Return out
End Sub
