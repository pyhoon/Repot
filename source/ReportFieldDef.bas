B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Declared dataset field.
'FormatMap is optional display metadata for data exporters (XLSX/ODS):
'the same shape as style and element formats. It does not affect layout.
Sub Class_Globals
	Public Name As String
	Public DataType As String
	Public FormatMap As Map
End Sub

Public Sub Initialize
	Name = ""
	DataType = "string"
	FormatMap.Initialize
End Sub
