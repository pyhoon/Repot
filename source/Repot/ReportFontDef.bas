B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Declared font family and fallback order. Nothing is embedded at load time.
Sub Class_Globals
	Public Name As String
Public Family As List
Public Size As Double
End Sub

Public Sub Initialize
	Name = ""
	Family.Initialize
	Size = 0
End Sub

Public Sub PrimaryFamily As String
	If Family.Size = 0 Then Return ""
	Return Family.Get(0)
End Sub
