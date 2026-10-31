B4J=true
Group=Expressions
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'A single lexical token produced by the expression scanner.
Sub Class_Globals
	Public TokenType As String
	Public Value As String
End Sub

Public Sub Initialize (T As String, V As String)
	TokenType = T
	Value = V
End Sub
