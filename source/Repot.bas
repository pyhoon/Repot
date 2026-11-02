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

Public Sub ExportHtml (OutputPath As String) As Boolean
	Dim ex As ReportHtmlExporter
	ex.Initialize(Diagnostics)
	Return ex.Export(Result.RenderDocument, OutputPath)
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