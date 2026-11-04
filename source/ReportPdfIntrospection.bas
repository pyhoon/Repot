B4A=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' B4A PDF introspection via android.graphics.pdf.PdfRenderer (API 16+).
'
' Verifies an exported PDF and reports its page count. Text extraction is
' not offered here: PdfRenderer renders pages but exposes no text API, so
' ExtractText stays B4J-only (PDFBox; see ReportPdfExporter).
'
' Everything is JavaObject reflection on Android framework classes — no
' inline Java and no third-party jars:
'   ParcelFileDescriptor.open(File, MODE_READ_ONLY) -> PdfRenderer
'   -> getPageCount -> close(Fd)
' MODE_READ_ONLY = 0x10000000. A missing or invalid file throws and the
' caller receives 0 (fail silent by contract: this is inspection, not
' validation; ReportDiagnostics stays the validation channel).

Sub Process_Globals
End Sub

'Returns the number of pages in a PDF file, or 0 when the file does not
'exist or cannot be opened as a PDF. Path is the absolute file path.
Public Sub GetPdfPageCount (Path As String) As Int
	#If B4A
	Try
		Dim fileJO As JavaObject
		fileJO.InitializeNewInstance("java.io.File", Array(Path))
		Dim MODE_READ_ONLY As Int = 268435456 ' 0x10000000
		Dim pfdStatic As JavaObject
		pfdStatic.InitializeStatic("android.os.ParcelFileDescriptor")
		Dim descriptor As JavaObject = pfdStatic.RunMethod("open", Array(fileJO, MODE_READ_ONLY))
		Dim renderer As JavaObject
		renderer.InitializeNewInstance("android.graphics.pdf.PdfRenderer", Array(descriptor))
		Dim count As Int = renderer.RunMethod("getPageCount", Null)
		renderer.RunMethod("close", Null)
		descriptor.RunMethod("close", Null)
		Return count
	Catch
		Log("GetPdfPageCount failed: " & LastException.Message)
		Return 0
	End Try
	#End If
	Return 0
End Sub