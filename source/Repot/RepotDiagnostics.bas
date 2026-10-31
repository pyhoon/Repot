B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Ordered diagnostic collection returned by loading and binding.
Sub Class_Globals
	Public Items As List
End Sub

Public Sub Initialize
	Items.Initialize
End Sub

Public Sub AddError (Code As String, Message As String, Path As String)
	AddErrorAt(Code, Message, Path, "")
End Sub

Public Sub AddErrorAt (Code As String, Message As String, Path As String, ElementId As String)
	AddOne("error", Code, Message, Path, ElementId)
End Sub

Public Sub AddWarning (Code As String, Message As String, Path As String)
	AddWarningAt(Code, Message, Path, "")
End Sub

Public Sub AddWarningAt (Code As String, Message As String, Path As String, ElementId As String)
	AddOne("warning", Code, Message, Path, ElementId)
End Sub

Private Sub AddOne (Severity As String, Code As String, Message As String, Path As String, ElementId As String)
	Dim d As RepotDiagnostic
	d.Initialize(Severity, Code, Message)
	d.Path = Path
	d.ElementId = ElementId
	Items.Add(d)
End Sub

Public Sub ErrorCount As Int
	Dim n As Int = 0
	For Each d As RepotDiagnostic In Items
		If d.Severity = "error" Then n = n + 1
	Next
	Return n
End Sub

Public Sub WarningCount As Int
	Dim n As Int = 0
	For Each d As RepotDiagnostic In Items
		If d.Severity = "warning" Then n = n + 1
	Next
	Return n
End Sub

Public Sub HasErrors As Boolean
	Return ErrorCount > 0
End Sub

Public Sub Merge (Other As RepotDiagnostics)
	For Each d As RepotDiagnostic In Other.Items
		Items.Add(d)
	Next
End Sub

Public Sub Errors As List
	Dim out As List
	out.Initialize
	For Each d As RepotDiagnostic In Items
		If d.Severity = "error" Then out.Add(d)
	Next
	Return out
End Sub

Public Sub Warnings As List
	Dim out As List
	out.Initialize
	For Each d As RepotDiagnostic In Items
		If d.Severity = "warning" Then out.Add(d)
	Next
	Return out
End Sub

Public Sub ToLines As List
	Dim out As List
	out.Initialize
	For Each d As RepotDiagnostic In Items
		out.Add(d.ToText)
	Next
	Return out
End Sub
