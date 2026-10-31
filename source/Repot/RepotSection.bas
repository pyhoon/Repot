B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'One band. Height is the declared minimum in points; layout may grow it.
Sub Class_Globals
	Public SectionType As String
Public Id As String
Public Height As Double
Public DataSet As String
Public GroupId As String
Public Elements As List
Public KeepTogether As Boolean
Public PageBreak As String
Public VisibleExpression As String
Public SourcePath As String
End Sub

Public Sub Initialize
	SectionType = ""
	Id = ""
	Height = 0
	DataSet = ""
	GroupId = ""
	Elements.Initialize
	KeepTogether = False
	PageBreak = ""
	VisibleExpression = ""
	SourcePath = ""
End Sub

Public Sub ElementById (ElementId As String) As RepotElement
	For Each e As RepotElement In Elements
		If e.Id = ElementId Then Return e
	Next
	Return Null
End Sub

Public Sub IsGroupSection As Boolean
	Return SectionType = "GroupHeader" Or SectionType = "GroupFooter"
End Sub
