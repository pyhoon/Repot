B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Declared parameter supplied by the host application.
Sub Class_Globals
	Public Name As String
	Public DataType As String
	Public Required As Boolean
	Public HasDefault As Boolean
	Public DefaultValue As Object
End Sub

Public Sub Initialize
	Name = ""
	DataType = "string"
	Required = False
	HasDefault = False
	DefaultValue = Null
End Sub
