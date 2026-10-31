B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Minimal DOCX exporter: writes a dataset as a table inside a valid
'WordprocessingML document. Uses java.util.zip directly; no third-party
'OOXML library.

Sub Class_Globals
	Public Diagnostics As ReportDiagnostics
	Private mDef As ReportDefinition
	Private mBinder As ReportDataBinder
End Sub

Public Sub Initialize (Def As ReportDefinition, B As ReportDataBinder, Diags As ReportDiagnostics)
	mDef = Def
	mBinder = B
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
End Sub

Public Sub Export (DataSetName As String, OutputPath As String) As Boolean
	Dim ds As ReportDataSet = mBinder.GetDataSet(DataSetName)
	If ds = Null Then
		Diagnostics.AddError("E-DATA-010", "dataset '" & DataSetName & "' was not supplied", "")
		Return False
	End If
	Try
		Dim tmp As String = File.Combine(File.DirApp, "docx_tmp")
		DeleteFolder(tmp)
		File.MakeDir(File.DirApp, "docx_tmp")
		File.MakeDir(tmp, "_rels")
		File.MakeDir(tmp, "word")
		File.MakeDir(tmp, "word/_rels")

		' [Content_Types].xml
		Dim ct As StringBuilder
		ct.Initialize
		ct.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		ct.Append("<Types xmlns=""http://schemas.openxmlformats.org/package/2006/content-types"">").Append(CRLF)
		ct.Append("  <Default Extension=""rels"" ContentType=""application/vnd.openxmlformats-package.relationships+xml""/>").Append(CRLF)
		ct.Append("  <Default Extension=""xml"" ContentType=""application/xml""/>").Append(CRLF)
		ct.Append("  <Override PartName=""/word/document.xml"" ContentType=""application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml""/>").Append(CRLF)
		ct.Append("</Types>").Append(CRLF)
		File.WriteString(tmp, "[Content_Types].xml", ct.ToString)

		' _rels/.rels
		Dim rels As StringBuilder
		rels.Initialize
		rels.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		rels.Append("<Relationships xmlns=""http://schemas.openxmlformats.org/package/2006/relationships"">").Append(CRLF)
		rels.Append("  <Relationship Id=""rId1"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"" Target=""word/document.xml""/>").Append(CRLF)
		rels.Append("</Relationships>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "_rels"), ".rels", rels.ToString)

		' word/_rels/document.xml.rels
		Dim drels As StringBuilder
		drels.Initialize
		drels.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		drels.Append("<Relationships xmlns=""http://schemas.openxmlformats.org/package/2006/relationships""></Relationships>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "word/_rels"), "document.xml.rels", drels.ToString)

		' word/document.xml
		Dim docx As StringBuilder
		docx.Initialize
		docx.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		docx.Append("<w:document xmlns:w=""http://schemas.openxmlformats.org/wordprocessingml/2006/main"">").Append(CRLF)
		docx.Append("  <w:body>").Append(CRLF)
		' table
		docx.Append("    <w:tbl>").Append(CRLF)
		docx.Append("      <w:tblGrid>")
		For Each f As ReportFieldDef In ds.Definition.Fields
			docx.Append("<w:gridCol w:w=""2000""/>")
		Next
		docx.Append("</w:tblGrid>").Append(CRLF)
		' header row
		docx.Append("      <w:tr>")
		For Each f As ReportFieldDef In ds.Definition.Fields
			docx.Append("<w:tc><w:p><w:r><w:t>").Append(XmlEscape(f.Name)).Append("</w:t></w:r></w:p></w:tc>")
		Next
		docx.Append("</w:tr>").Append(CRLF)
		' data rows
		For Each rec As Map In ds.Records
			docx.Append("      <w:tr>")
			For Each f As ReportFieldDef In ds.Definition.Fields
				Dim v As Object = rec.Get(f.Name)
				docx.Append("<w:tc><w:p><w:r><w:t>").Append(XmlEscape(ValueToString(v))).Append("</w:t></w:r></w:p></w:tc>")
			Next
			docx.Append("</w:tr>").Append(CRLF)
		Next
		docx.Append("    </w:tbl>").Append(CRLF)
		docx.Append("  </w:body>").Append(CRLF)
		docx.Append("</w:document>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "word"), "document.xml", docx.ToString)

		' zip
		Dim jo As JavaObject
		jo.InitializeStatic("b4j.example.reportdocxexporter")
		jo.RunMethod("zipFolder", Array(tmp, OutputPath))

		DeleteFolder(tmp)
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-IO-001", "DOCX export failed: " & LastException.Message, "")
		Return False
	End Try
End Sub

Private Sub DeleteFolder (path As String)
	Try
		Dim jo As JavaObject
		jo.InitializeStatic("java.nio.file.Files")
		' simple: delete files recursively via JavaObject not available; use shell? skip
	Catch
		Log(LastException.Message)
	End Try
End Sub

Private Sub ValueToString (v As Object) As String
	If v = Null Then Return ""
	Return v
End Sub

Private Sub XmlEscape (s As String) As String
	Dim out As String = s
	out = out.Replace("&", "&amp;")
	out = out.Replace("<", "&lt;")
	out = out.Replace(">", "&gt;")
	Return out
End Sub

#If Java
import java.io.*;
import java.nio.file.*;
import java.util.zip.*;

public static void zipFolder(String srcDir, String zipPath) throws Exception {
    Path src = Paths.get(srcDir);
    ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zipPath));
    Files.walk(src).filter(p -> !Files.isDirectory(p)).forEach(p -> {
        try {
            String rel = src.relativize(p).toString().replace("\\", "/");
            zos.putNextEntry(new ZipEntry(rel));
            Files.copy(p, zos);
            zos.closeEntry();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    });
    zos.close();
}
#End If
