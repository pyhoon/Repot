B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private mreq As ServletRequest 'ignore
	Private mresp As ServletResponse 'ignore
End Sub

Public Sub Initialize
	
End Sub

Sub Handle (req As ServletRequest, resp As ServletResponse)
	mreq = req
	mresp = resp
	RunExample
End Sub

Sub RunExample
    Dim fixtureDir As String = ""
    Dim candidates() As String = Array As String( _
        "..\..\..\fixtures\invoice-basic", _
        "..\..\..\..\fixtures\invoice-basic", _
        "..\..\fixtures\invoice-basic", _
        "fixtures\invoice-basic")
    For Each c As String In candidates
        If File.Exists(c, "template.repot") Then
            fixtureDir = c
            Exit
        End If
    Next
    If fixtureDir = "" Then fixtureDir = "..\..\..\fixtures\invoice-basic"
    Dim outDir As String = "."

    Dim r As Repot
    r.Initialize
    If r.LoadTemplate(fixtureDir, "template.repot") = False Then
        Log("Load errors:")
        For Each d As ReportDiagnostic In r.Diagnostics.Items
            Log("  " & d.Code & " " & d.Message)
        Next
        Return
    End If

    Dim params As Map = LoadJsonMap(fixtureDir, "params.json")
    For Each k As String In params.Keys
        r.SetParameter(k, params.Get(k))
    Next
    Dim data As Map = LoadJsonMap(fixtureDir, "data.json")
    For Each name As String In data.Keys
        Dim o As Object = data.Get(name)
        If o Is List Then
            r.SetDataSource(name, o)
        Else If o Is Map Then
            r.SetDataSourceSingle(name, o)
        End If
    Next

    Dim res As ReportResult = r.Build
    If res.Success = False Then
        Log("Build failed:")
        For Each d As ReportDiagnostic In res.Errors
            Log("  " & d.Code & " " & d.Message)
        Next
        Return
    End If
    Log("Rendered " & res.PageCount & " page(s), " & res.RecordCount & " record(s)")

    File.MakeDir(outDir, "")
    Dim htmlPath As String = File.Combine(outDir, "invoice.html")
    If r.ExportHtml(htmlPath) Then Log("HTML -> " & htmlPath) Else Log("HTML export failed")

    Dim pdfPath As String = File.Combine(outDir, "invoice.pdf")
    If r.ExportPdf(pdfPath) Then
        Log("PDF  -> " & pdfPath)
        ReportB4JOpen.OpenPdf(outDir, "invoice.pdf")
    Else
        Log("PDF export failed")
    End If

    For Each d As ReportDiagnostic In r.Diagnostics.Items
        Log("diag: " & d.Code & " " & d.Message)
    Next
End Sub

Private Sub LoadJsonMap(dir As String, name As String) As Map
    Dim parser As JSONParser
    parser.Initialize(File.ReadString(dir, name))
    Return parser.NextObject
End Sub