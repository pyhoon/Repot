B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Declared dataset. The engine never populates it; the host does.
Sub Class_Globals
	Public Name As String
Public Kind As String
Public Fields As List
Public Aggregates As List
End Sub

Public Sub Initialize
	Name = ""
	Kind = "rows"
	Fields.Initialize
	Aggregates.Initialize
End Sub

Public Sub FieldByName (FieldName As String) As ReportFieldDef
	For Each f As ReportFieldDef In Fields
		If f.Name = FieldName Then Return f
	Next
	Return Null
End Sub

Public Sub HasField (FieldName As String) As Boolean
	Return FieldByName(FieldName) <> Null
End Sub

Public Sub AggregateByName (AggregateName As String) As ReportAggregateDef
	For Each a As ReportAggregateDef In Aggregates
		If a.Name = AggregateName Then Return a
	Next
	Return Null
End Sub
