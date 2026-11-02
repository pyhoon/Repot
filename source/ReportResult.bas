B4J=true
Group=Core
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Immutable-ish build result returned by Repot.Build. Applications read the
'scalar fields and diagnostics; the render document is an opaque handle for
'exporters.

Sub Class_Globals
	Public Success As Boolean
	Public Errors As List
	Public Warnings As List
	Public PageCount As Int
	Public RecordCount As Int
	Public SourceVersion As String
	Public RenderDocument As ReportRenderDocument
End Sub

Public Sub Initialize
	Success = False
	Errors.Initialize
	Warnings.Initialize
	PageCount = 0
	RecordCount = 0
	SourceVersion = ""
	RenderDocument = Null
End Sub