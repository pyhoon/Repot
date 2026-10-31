B4J=true
Group=Expressions
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Evaluation context for expressions: parameters, the current record,
'aggregates and page numbers. Datasets are reachable by name.
Sub Class_Globals
	Public Params As Map
	Public CurrentRecord As Map
	Public CurrentDataSet As String
	Public DataSets As Map
	Public Aggregates As Map
	Public PageNumber As Int
	Public PageCount As Int
End Sub

Public Sub Initialize
	Params.Initialize
	CurrentRecord.Initialize
	CurrentDataSet = ""
	DataSets.Initialize
	Aggregates.Initialize
	PageNumber = 1
	PageCount = 1
End Sub
