B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'One structured diagnostic. Codes are stable strings; see docs/errors.md.
Sub Class_Globals
	Public Severity As String
Public Code As String
Public Message As String
Public ElementId As String
Public Path As String
Public Hint As String
End Sub

Public Sub Initialize (Severity1 As String, Code1 As String, Message1 As String)
	Severity = Severity1
	Code = Code1
	Message = Message1
	ElementId = ""
	Path = ""
	Hint = ""
End Sub

Public Sub ToText As String
	Dim s As String = Severity & " " & Code
	If Path.Length > 0 Then s = s & " " & Path
	If ElementId.Length > 0 Then s = s & " [" & ElementId & "]"
	Return s & ": " & Message
End Sub
