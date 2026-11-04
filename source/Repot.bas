B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Unified facade over the engine: load a template, bind data and parameters,
'build once, then export to any format without re-running layout.
'
'Build is synchronous. The underlying modules remain public for advanced use.

Sub Class_Globals
	Public Diagnostics As ReportDiagnostics
	Public Result As ReportResult
	Public SourceDir As String
	'Optional TrueType fonts for the B4J PDF exporter.
	Public FontFile As String
	Public FontFileBold As String
	'Used by the data exporters when no dataset name is passed.
	Public DefaultDataSet As String
	Private mLoader As ReportTemplateLoader
	Private mDef As ReportDefinition
	Private mBinder As ReportDataBinder
End Sub

Public Sub Initialize
	Diagnostics.Initialize
	Result.Initialize
	SourceDir = ""
	FontFile = ""
	FontFileBold = ""
	DefaultDataSet = ""
End Sub

Public Sub LoadTemplate (Dir As String, FileName As String) As Boolean
	Diagnostics.Initialize
	mLoader.Initialize
	mDef = mLoader.LoadFromFile(Dir, FileName)
	Diagnostics.Merge(mLoader.Diagnostics)
	If mDef = Null Or Diagnostics.HasErrors Then Return False
	mBinder.Initialize(mDef)
	SourceDir = mDef.SourceDir
	If DefaultDataSet = "" Then DefaultDataSet = FirstRowDataSet
	Return True
End Sub

Public Sub LoadTemplateText (Text As String, BaseDir As String) As Boolean
	Diagnostics.Initialize
	mLoader.Initialize
	mDef = mLoader.LoadFromString(Text, BaseDir)
	Diagnostics.Merge(mLoader.Diagnostics)
	If mDef = Null Or Diagnostics.HasErrors Then Return False
	mBinder.Initialize(mDef)
	SourceDir = BaseDir
	If DefaultDataSet = "" Then DefaultDataSet = FirstRowDataSet
	Return True
End Sub

Public Sub SetParameter (Name As String, Value As Object)
	mBinder.SetParameter(Name, Value)
End Sub

Public Sub SetParameterInt (Name As String, Value As Int)
	mBinder.SetParameterInt(Name, Value)
End Sub

Public Sub SetParameterDouble (Name As String, Value As Double)
	mBinder.SetParameterDouble(Name, Value)
End Sub

Public Sub SetParameterBool (Name As String, Value As Boolean)
	mBinder.SetParameterBool(Name, Value)
End Sub

Public Sub SetParameterDate (Name As String, Value As Long)
	mBinder.SetParameterDate(Name, Value)
End Sub

Public Sub SetDataSource (Name As String, Rows As List)
	mBinder.SetDataSource(Name, Rows)
End Sub

Public Sub SetDataSourceSingle (Name As String, Record As Map)
	mBinder.SetDataSourceSingle(Name, Record)
End Sub

'Builds the render document once. Call Export* afterwards.
Public Sub Build As ReportResult
	Diagnostics.Initialize
	Result.Initialize
	If mDef = Null Then
		Diagnostics.AddError("E-API-001", "no template loaded", "")
		FinishResult
		Return Result
	End If
	If mBinder.Validate = False Then
		Diagnostics.Merge(mBinder.Diagnostics)
		FinishResult
		Return Result
	End If
	Diagnostics.Merge(mBinder.Diagnostics)

	Dim measure As ReportB4JMeasure
	measure.Initialize(Diagnostics)
	Dim pag As ReportPaginator
	pag.Initialize(mDef, mBinder, measure, Diagnostics)
	Result.RenderDocument = pag.Render
	Result.SourceVersion = mDef.SchemaVersion
	Result.PageCount = Result.RenderDocument.PageCount
	Result.RecordCount = CountRecords
	FinishResult
	Return Result
End Sub

Private Sub FinishResult
	Result.Success = Diagnostics.HasErrors = False
	Result.Errors = Diagnostics.Errors
	Result.Warnings = Diagnostics.Warnings
End Sub

Private Sub CountRecords As Int
	Dim n As Int = 0
	If mBinder = Null Then Return 0
	For Each dsName As String In mBinder.DataSets.Keys
		Dim ds As ReportDataSet = mBinder.DataSets.Get(dsName)
		If ds <> Null Then n = n + ds.Count
	Next
	Return n
End Sub

Private Sub FirstRowDataSet As String
	If mDef = Null Then Return ""
	For Each dsName As String In mDef.DataSets.Keys
		Dim d As ReportDataSetDef = mDef.DataSets.Get(dsName)
		If d.Kind = "rows" Then Return dsName
	Next
	Return ""
End Sub

Public Sub ExportPdf (OutputPath As String) As Boolean
	Dim ex As ReportPdfExporter
	ex.Initialize(Diagnostics)
	ex.SourceDir = SourceDir
	ex.FontFile = FontFile
	ex.FontFileBold = FontFileBold
	Return ex.Export(Result.RenderDocument, OutputPath)
End Sub

'PDF introspection on an exported file. Returns the page count (0 when
'the file cannot be read). B4A walks the file with PdfRenderer; B4J uses
'the PDFBox static helper in ReportPdfExporter.
Public Sub GetPdfPageCount (Path As String) As Int
	#If B4A
	Return ReportPdfIntrospection.GetPdfPageCount(Path)
	#Else If B4J
	Dim ex As ReportPdfExporter
	ex.Initialize(Diagnostics)
	Return ex.PageCount(Path)
	#End If
	Return 0
End Sub

'Extracts text from an exported PDF. B4J-biased operation through PDFBox;
'android's PdfRenderer has no text API, so B4A returns "".
Public Sub ExtractPdfText (Path As String) As String
	#If B4A
	Return ""
	#Else If B4J
	Dim ex As ReportPdfExporter
	ex.Initialize(Diagnostics)
	Return ex.ExtractText(Path)
	#End If
	Return ""
End Sub

'SaveAs: returns the SAF CreateDocument intent the host must launch for a
'result, or the chosen path directly on B4J (Null when the host must act,
'"" when the caller passed an empty title, "" when the launch code belongs
'to the host). See ReportSaveAs for the full wiring.
Public Sub SaveAsPdfIntent (Mime As String, Title As String) As Object
	#If B4A
	Return ReportSaveAs.CreateDocumentIntent(Mime, Title)
	#Else If B4J
	Log("SaveAs: B4J has no SAF; use the existing OutputPath or an IDE save dialog")
	Return Null
	#End If
End Sub

Public Sub ExportCsv (OutputPath As String) As Boolean
	Dim ex As ReportDataExporter
	ex.Initialize(mDef, mBinder, Diagnostics)
	Return ex.ExportCsv(DefaultDataSet, OutputPath)
End Sub

Public Sub ExportCsvOf (DataSetName As String, OutputPath As String) As Boolean
	Dim ex As ReportDataExporter
	ex.Initialize(mDef, mBinder, Diagnostics)
	Return ex.ExportCsv(DataSetName, OutputPath)
End Sub

Public Sub ExportJson (OutputPath As String) As Boolean
	Dim ex As ReportDataExporter
	ex.Initialize(mDef, mBinder, Diagnostics)
	Return ex.ExportJson(DefaultDataSet, OutputPath)
End Sub

Public Sub ExportXml (OutputPath As String) As Boolean
	Dim ex As ReportDataExporter
	ex.Initialize(mDef, mBinder, Diagnostics)
	Return ex.ExportXml(DefaultDataSet, OutputPath, "report")
End Sub

Public Sub ExportDocx (OutputPath As String) As Boolean
	Dim ex As ReportDocxExporter
	ex.Initialize(mDef, mBinder, Diagnostics)
	Return ex.Export(DefaultDataSet, OutputPath)
End Sub

Public Sub ExportXlsx (OutputPath As String) As Boolean
	Dim ex As ReportXlsxExporter
	ex.Initialize(mDef, mBinder, Diagnostics)
	Return ex.Export(DefaultDataSet, OutputPath)
End Sub

Public Sub ExportHtml (OutputPath As String) As Boolean
	Dim ex As ReportHtmlExporter
	ex.Initialize(Diagnostics)
	Return ex.Export(Result.RenderDocument, OutputPath)
End Sub

'Prints an already exported PDF (B4A: system dialog; B4J: opens the viewer).
Public Sub PrintPdf (Dir As String, FileName As String, JobName As String) As Boolean
	Return ReportPrint.PrintPdf(Dir, FileName, JobName)
End Sub

'B4A only: prints the rendered report as HTML.
Public Sub PrintHtml (JobName As String) As Boolean
	Dim ex As ReportHtmlExporter
	ex.Initialize(Diagnostics)
	Return ReportPrint.PrintHtml(JobName, ex.ToHtml(Result.RenderDocument))
End Sub