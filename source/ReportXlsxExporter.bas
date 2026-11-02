B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Minimal XLSX exporter: writes a dataset as a worksheet. Uses
'java.util.zip directly; no third-party OOXML library.

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
		#If B4A
		Dim tmp As String = File.Combine(File.DirInternal, "xlsx_tmp")
		#Else
		Dim tmp As String = File.Combine(File.DirApp, "xlsx_tmp")
		#End If
		DeleteFolder(tmp)
		#If B4A
		File.MakeDir(File.DirInternal, "xlsx_tmp")
		#Else
		File.MakeDir(File.DirApp, "xlsx_tmp")
		#End If
		File.MakeDir(tmp, "_rels")
		File.MakeDir(tmp, "xl")
		File.MakeDir(tmp, "xl/_rels")
		File.MakeDir(tmp, "xl/worksheets")

		' [Content_Types].xml
		Dim ct As StringBuilder
		ct.Initialize
		ct.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		ct.Append("<Types xmlns=""http://schemas.openxmlformats.org/package/2006/content-types"">").Append(CRLF)
		ct.Append("  <Default Extension=""rels"" ContentType=""application/vnd.openxmlformats-package.relationships+xml""/>").Append(CRLF)
		ct.Append("  <Default Extension=""xml"" ContentType=""application/xml""/>").Append(CRLF)
		ct.Append("  <Override PartName=""/xl/workbook.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml""/>").Append(CRLF)
		ct.Append("  <Override PartName=""/xl/worksheets/sheet1.xml"" ContentType=""application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml""/>").Append(CRLF)
		ct.Append("</Types>").Append(CRLF)
		File.WriteString(tmp, "[Content_Types].xml", ct.ToString)

		' _rels/.rels
		Dim rels As StringBuilder
		rels.Initialize
		rels.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		rels.Append("<Relationships xmlns=""http://schemas.openxmlformats.org/package/2006/relationships"">").Append(CRLF)
		rels.Append("  <Relationship Id=""rId1"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"" Target=""xl/workbook.xml""/>").Append(CRLF)
		rels.Append("</Relationships>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "_rels"), ".rels", rels.ToString)

		' xl/_rels/workbook.xml.rels
		Dim wrels As StringBuilder
		wrels.Initialize
		wrels.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		wrels.Append("<Relationships xmlns=""http://schemas.openxmlformats.org/package/2006/relationships"">").Append(CRLF)
		wrels.Append("  <Relationship Id=""rId1"" Type=""http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"" Target=""worksheets/sheet1.xml""/>").Append(CRLF)
		wrels.Append("</Relationships>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "xl/_rels"), "workbook.xml.rels", wrels.ToString)

		' xl/workbook.xml
		Dim wb As StringBuilder
		wb.Initialize
		wb.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		wb.Append("<workbook xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main"" xmlns:r=""http://schemas.openxmlformats.org/officeDocument/2006/relationships"">").Append(CRLF)
		wb.Append("  <sheets><sheet name=""Sheet1"" sheetId=""1"" r:id=""rId1""/></sheets>").Append(CRLF)
		wb.Append("</workbook>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "xl"), "workbook.xml", wb.ToString)

		' xl/worksheets/sheet1.xml
		Dim sh As StringBuilder
		sh.Initialize
		sh.Append("<?xml version=""1.0"" encoding=""UTF-8"" standalone=""yes""?>").Append(CRLF)
		sh.Append("<worksheet xmlns=""http://schemas.openxmlformats.org/spreadsheetml/2006/main"">").Append(CRLF)
		sh.Append("  <sheetData>").Append(CRLF)
		' header row
		sh.Append("    <row r=""1"">")
		Dim ci As Int = 1
		For Each f As ReportFieldDef In ds.Definition.Fields
			sh.Append("<c r=""").Append(ColLetter(ci)).Append("1"" t=""inlineStr""><is><t>").Append(XmlEscape(f.Name)).Append("</t></is></c>")
			ci = ci + 1
		Next
		sh.Append("</row>").Append(CRLF)
		' data rows
		Dim ri As Int = 2
		For Each rec As Map In ds.Records
			sh.Append("    <row r=""").Append(ri).Append(""">")
			ci = 1
			For Each f As ReportFieldDef In ds.Definition.Fields
				Dim v As Object = rec.Get(f.Name)
				sh.Append("<c r=""").Append(ColLetter(ci)).Append(ri).Append(""" t=""inlineStr""><is><t>").Append(XmlEscape(ValueToString(v))).Append("</t></is></c>")
				ci = ci + 1
			Next
			sh.Append("</row>").Append(CRLF)
			ri = ri + 1
		Next
		sh.Append("  </sheetData>").Append(CRLF)
		sh.Append("</worksheet>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "xl/worksheets"), "sheet1.xml", sh.ToString)

		Dim jo As JavaObject = Me
		jo.RunMethod("zipFolder", Array(tmp, OutputPath))

		DeleteFolder(tmp)
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-IO-001", "XLSX export failed: " & LastException.Message, "")
		Return False
	End Try
End Sub

Private Sub ColLetter (n As Int) As String
	Dim letters As String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	If n <= 26 Then Return letters.SubString2(n - 1, n)
	' beyond Z not needed for these datasets
	Return "A"
End Sub

Private Sub DeleteFolder (path As String)
	
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
import java.util.zip.*;

public static void zipFolder(String srcDir, String zipPath) throws Exception {
    // Lambda-free: Android's dexer cannot desugar invokedynamic from B4A-generated code.
    ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zipPath));
    try {
        java.util.ArrayList<File> files = new java.util.ArrayList<File>();
        java.util.ArrayList<String> rels = new java.util.ArrayList<String>();
        collect(new File(srcDir), "", files, rels);
        for (int i = 0; i < files.size(); i++) {
            zos.putNextEntry(new ZipEntry(rels.get(i)));
            FileInputStream fis = new FileInputStream(files.get(i));
            byte[] buf = new byte[8192];
            int n;
            while ((n = fis.read(buf)) > 0) zos.write(buf, 0, n);
            fis.close();
            zos.closeEntry();
        }
    } finally {
        zos.close();
    }
}

private static void collect(File dir, String prefix, java.util.ArrayList<File> files, java.util.ArrayList<String> rels) {
    File[] items = dir.listFiles();
    if (items == null) return;
    for (int i = 0; i < items.length; i++) {
        String rel = prefix.length() == 0 ? items[i].getName() : prefix + "/" + items[i].getName();
        if (items[i].isDirectory()) collect(items[i], rel, files, rels);
        else { files.add(items[i]); rels.add(rel); }
    }
}
#End If
