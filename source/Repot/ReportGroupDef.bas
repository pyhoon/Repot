B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Declared group. Declaration order is nesting order, outermost first.
Sub Class_Globals
	Public Id As String
Public DataSet As String
Public KeyExpression As String
Public Sort As List
Public RepeatHeader As Boolean
Public Aggregates As List
End Sub

Public Sub Initialize
	Id = ""
	DataSet = ""
	KeyExpression = ""
	Sort.Initialize
	RepeatHeader = False
	Aggregates.Initialize
End Sub

Public Sub AggregateByName (AggregateName As String) As ReportAggregateDef
	For Each a As ReportAggregateDef In Aggregates
		If a.Name = AggregateName Then Return a
	Next
	Return Null
End Sub
