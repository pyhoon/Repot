B4A=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' B4A-only helper: open a file (e.g. a generated PDF) in a viewer app.

Sub Process_Globals
	Private provider As FileProvider
	Private isInit As Boolean
End Sub

Private Sub EnsureInit
	If isInit Then Return
	provider.Initialize
	isInit = True
End Sub

Public Sub OpenPdf(Dir As String, FileName As String)
	#If B4A
	EnsureInit
	Try
		Dim Success As Boolean = False
		Try
			File.Copy(Dir, FileName, provider.SharedFolder, FileName)
			Success = True
		Catch
			Log("OpenPDF copy err: " & LastException)
		End Try
		If Success = False Then
			Log("OpenPDF: copy failed")
			Return
		End If
		Dim docIntent As Intent
		docIntent.Initialize(docIntent.ACTION_VIEW, "")
		provider.SetFileUriAsIntentData(docIntent, FileName)
		docIntent.SetType("application/pdf")
		docIntent.Flags = Bit.Or(1, 2)
		StartActivity(docIntent)
	Catch
		Log("OpenPDF error: " & LastException)
	End Try
	#End If
End Sub