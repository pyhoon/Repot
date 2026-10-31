B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=14.2
@EndOfDesignText@
'Code module
'Subs in this code module will be accessible from all modules.
Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.

End Sub

Public Sub GetFileParent (FullPath As String) As String
	Dim i As Int = FullPath.LastIndexOf("/")
	If i > -1 Then
		Return FullPath.SubString2(0, i)
	Else
		Return "" ' No parent directory found
	End If
End Sub

Public Sub GetFileName (FullPath As String) As String
	Return FullPath.SubString(FullPath.LastIndexOf("/") + 1)
End Sub