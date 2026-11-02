B4J=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' B4J-only helper: open a file (e.g. a generated PDF) in the default viewer.

Sub Process_Globals
End Sub

Public Sub OpenPdf(Dir As String, FileName As String)
	#If B4J
	Dim fx As JFX
	fx.ShowExternalDocument(File.GetUri(Dir, FileName))
	#End If
End Sub