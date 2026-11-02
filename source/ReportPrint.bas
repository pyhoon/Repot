B4J=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' Print helpers.
'
' B4A: uses the Printing library (system print dialog) for PDF and HTML.
' B4J: opens the PDF in the default viewer; printing is then a viewer action.
' The engine never prints directly on a background thread.

Sub Process_Globals
End Sub

'Prints an existing PDF file. Dir / FileName identify the file.
Public Sub PrintPdf (Dir As String, FileName As String, JobName As String) As Boolean
	#If B4A
	Dim p As Printer
	p.Initialize("")
	If p.PrintSupported = False Then Return False
	p.PrintPdf(JobName, Dir, FileName)
	Return True
	#Else If B4J
	ReportB4JOpen.OpenPdf(Dir, FileName)
	Return True
	#End If
	Return False
End Sub

'B4A only: prints an HTML string through the system print dialog.
Public Sub PrintHtml (JobName As String, Html As String) As Boolean
	#If B4A
	Dim p As Printer
	p.Initialize("")
	If p.PrintSupported = False Then Return False
	p.PrintHtml(JobName, Html)
	Return True
	#End If
	Return False
End Sub