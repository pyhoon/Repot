B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Minimal ODS (OpenDocument spreadsheet) exporter: writes a dataset as a
'worksheet table inside a valid ODF 1.2 package. Uses java.util.zip
'directly; no third-party ODF library. The mimetype entry is written
'first and uncompressed, as the ODF package requires.

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
		Dim tmp As String = File.Combine(File.DirInternal, "ods_tmp")
		#Else
		Dim tmp As String = File.Combine(File.DirApp, "ods_tmp")
		#End If
		DeleteFolder(tmp)
		#If B4A
		File.MakeDir(File.DirInternal, "ods_tmp")
		#Else
		File.MakeDir(File.DirApp, "ods_tmp")
		#End If
		File.MakeDir(tmp, "META-INF")

		' One cell style and one column style per field, plus the number/date
		' data styles they reference. Names are positional, so output is
		' deterministic. Excel ignores the cached text:p for display: it
		' needs the data style attached through table:style-name.
		Dim colCount As Int = ds.Definition.Fields.Size
		Dim widths As List
		widths.Initialize
		Dim hasStyle As List
		hasStyle.Initialize
		Dim isDate As List
		isDate.Initialize
		Dim ci As Int = 1
		For Each f As ReportFieldDef In ds.Definition.Fields
			Dim w As Int = f.Name.Length
			For Each rec0 As Map In ds.Records
				Dim t0 As String = ReportSpreadsheet.DisplayText(rec0.Get(f.Name), f.FormatMap, f.DataType)
				If t0.Length > w Then w = t0.Length
			Next
			If w < 8 Then w = 8
			If w > 60 Then w = 60
			widths.Add(w + 2)

			Dim code As String = ReportSpreadsheet.ExcelFormatCode(f.FormatMap, f.DataType)
			hasStyle.Add(code <> "General")
			isDate.Add(ReportSpreadsheet.IsDateFormat(f.FormatMap, f.DataType))
			ci = ci + 1
		Next

		' content.xml: the dataset as one table (header row + data rows)
		Dim content As StringBuilder
		content.Initialize
		content.Append("<?xml version=""1.0"" encoding=""UTF-8""?>").Append(CRLF)
		content.Append("<office:document-content xmlns:office=""urn:oasis:names:tc:opendocument:xmlns:office:1.0"" xmlns:text=""urn:oasis:names:tc:opendocument:xmlns:text:1.0"" xmlns:table=""urn:oasis:names:tc:opendocument:xmlns:table:1.0"" xmlns:style=""urn:oasis:names:tc:opendocument:xmlns:style:1.0"" xmlns:number=""urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"" office:version=""1.2"">").Append(CRLF)
		content.Append("  <office:automatic-styles>").Append(CRLF)
		ci = 1
		For Each f As ReportFieldDef In ds.Definition.Fields
			Dim hs As Boolean = hasStyle.Get(ci - 1)
			Dim fd As Boolean = isDate.Get(ci - 1)
			If hs Then
				If fd Then
					content.Append("    ").Append(ReportSpreadsheet.OdfDateStyleFor("D" & ci, f.FormatMap, f.DataType)).Append(CRLF)
					content.Append("    <style:style style:name=""ce").Append(ci).Append(""" style:family=""table-cell"" style:data-style-name=""D").Append(ci).Append("""/>").Append(CRLF)
				Else
					content.Append("    ").Append(ReportSpreadsheet.OdfNumberStyle("N" & ci, f.FormatMap, f.DataType)).Append(CRLF)
					content.Append("    <style:style style:name=""ce").Append(ci).Append(""" style:family=""table-cell"" style:data-style-name=""N").Append(ci).Append("""/>").Append(CRLF)
				End If
			End If
			ci = ci + 1
		Next
		ci = 1
		For Each f As ReportFieldDef In ds.Definition.Fields
			Dim wv As Double = widths.Get(ci - 1)
			Dim cm As Double = wv * 0.21
			content.Append("    <style:style style:name=""co").Append(ci).Append(""" style:family=""table-column""><style:table-column-properties style:column-width=""").Append(ReportUnits.FormatNumber(cm, 2)).Append("cm""/>").Append("</style:style>").Append(CRLF)
			ci = ci + 1
		Next
		content.Append("  </office:automatic-styles>").Append(CRLF)
		content.Append("  <office:body>").Append(CRLF)
		content.Append("    <office:spreadsheet>").Append(CRLF)
		content.Append("      <table:table table:name=""Report"">").Append(CRLF)
		ci = 1
		For Each f As ReportFieldDef In ds.Definition.Fields
			content.Append("        <table:table-column table:style-name=""co").Append(ci).Append("""/>").Append(CRLF)
			ci = ci + 1
		Next
		' header row
		content.Append("        <table:table-row>")
		For Each f As ReportFieldDef In ds.Definition.Fields
			content.Append("<table:table-cell office:value-type=""string""><text:p>").Append(XmlEscape(f.Name)).Append("</text:p></table:table-cell>")
		Next
		content.Append("</table:table-row>").Append(CRLF)
		' data rows: the cell type follows the bound value
		For Each rec As Map In ds.Records
			content.Append("        <table:table-row>")
			ci = 1
			For Each f As ReportFieldDef In ds.Definition.Fields
				Dim v As Object = rec.Get(f.Name)
				Dim kind As String = ReportSpreadsheet.CellKind(v, f)
				Dim txt As String = ReportSpreadsheet.DisplayText(v, f.FormatMap, f.DataType)
				If kind = "empty" Then
					content.Append("<table:table-cell/>")
				Else If kind = "number" Then
					Dim d As Double = v
					content.Append("<table:table-cell table:style-name=""ce").Append(ci).Append(""" office:value-type=""float"" office:value=""").Append(ReportSpreadsheet.InvariantNumber(d)).Append("""><text:p>").Append(XmlEscape(txt)).Append("</text:p></table:table-cell>")
				Else If kind = "date" Then
					content.Append("<table:table-cell table:style-name=""ce").Append(ci).Append(""" office:value-type=""date"" office:date-value=""").Append(ReportSpreadsheet.OdfDateValue(v)).Append("""><text:p>").Append(XmlEscape(txt)).Append("</text:p></table:table-cell>")
				Else If kind = "boolean" Then
					Dim b As Boolean = v
					content.Append("<table:table-cell office:value-type=""boolean"" office:boolean-value=""")
					If b Then
						content.Append("true")
					Else
						content.Append("false")
					End If
					content.Append("""><text:p>").Append(XmlEscape(txt)).Append("</text:p></table:table-cell>")
				Else
					content.Append("<table:table-cell office:value-type=""string""><text:p>").Append(XmlEscape(txt)).Append("</text:p></table:table-cell>")
				End If
				ci = ci + 1
			Next
			content.Append("</table:table-row>").Append(CRLF)
		Next
		content.Append("      </table:table>").Append(CRLF)
		content.Append("    </office:spreadsheet>").Append(CRLF)
		content.Append("  </office:body>").Append(CRLF)
		content.Append("</office:document-content>").Append(CRLF)
		File.WriteString(tmp, "content.xml", content.ToString)

		' META-INF/manifest.xml
		'The root file-entry carries manifest:version: ODF 1.2 consumers
		'(Excel's importer included) use it to select the schema version
		'for the package; without it the document is treated as pre-1.2
		'and Excel reports a content problem on open.
		Dim manifest As StringBuilder
		manifest.Initialize
		manifest.Append("<?xml version=""1.0"" encoding=""UTF-8""?>").Append(CRLF)
		manifest.Append("<manifest:manifest xmlns:manifest=""urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"" manifest:version=""1.2"">").Append(CRLF)
		manifest.Append("  <manifest:file-entry manifest:full-path=""/"" manifest:version=""1.2"" manifest:media-type=""application/vnd.oasis.opendocument.spreadsheet""/>").Append(CRLF)
		manifest.Append("  <manifest:file-entry manifest:full-path=""content.xml"" manifest:media-type=""text/xml""/>").Append(CRLF)
		manifest.Append("  <manifest:file-entry manifest:full-path=""styles.xml"" manifest:media-type=""text/xml""/>").Append(CRLF)
		manifest.Append("  <manifest:file-entry manifest:full-path=""meta.xml"" manifest:media-type=""text/xml""/>").Append(CRLF)
		manifest.Append("</manifest:manifest>").Append(CRLF)
		File.WriteString(File.Combine(tmp, "META-INF"), "manifest.xml", manifest.ToString)

		' styles.xml / meta.xml: spec-optional but part of every real
		' producer's package (LibreOffice, Excel); some consumers are
		' strict about the package shape, so write the minimal parts.
		Dim styles As StringBuilder
		styles.Initialize
		styles.Append("<?xml version=""1.0"" encoding=""UTF-8""?>").Append(CRLF)
		styles.Append("<office:document-styles xmlns:office=""urn:oasis:names:tc:opendocument:xmlns:office:1.0"" office:version=""1.2"">").Append(CRLF)
		styles.Append("  <office:styles/>").Append(CRLF)
		styles.Append("</office:document-styles>").Append(CRLF)
		File.WriteString(tmp, "styles.xml", styles.ToString)

		Dim meta As StringBuilder
		meta.Initialize
		meta.Append("<?xml version=""1.0"" encoding=""UTF-8""?>").Append(CRLF)
		meta.Append("<office:document-meta xmlns:office=""urn:oasis:names:tc:opendocument:xmlns:office:1.0"" office:version=""1.2"">").Append(CRLF)
		meta.Append("  <office:meta/>").Append(CRLF)
		meta.Append("</office:document-meta>").Append(CRLF)
		File.WriteString(tmp, "meta.xml", meta.ToString)

		' zip: mimetype first and uncompressed, then the parts
		Dim jo As JavaObject = Me
		jo.RunMethod("zipOdf", Array(tmp, OutputPath, "application/vnd.oasis.opendocument.spreadsheet"))

		DeleteFolder(tmp)
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-IO-001", "ODS export failed: " & LastException.Message, "")
		Return False
	End Try
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

/*
 * ODF package writer: the "mimetype" entry must be the first entry in
 * the zip and stored uncompressed (ODF 1.2 package requirement), so it
 * is written explicitly before the directory parts are added.
 */
public static void zipOdf(String srcDir, String zipPath, String mediaType) throws Exception {
    // Lambda-free: Android's dexer cannot desugar invokedynamic from B4A-generated code.
    ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(zipPath));
    try {
        byte[] mt = mediaType.getBytes("UTF-8");
        ZipEntry mtEntry = new ZipEntry("mimetype");
        mtEntry.setMethod(ZipEntry.STORED);
        mtEntry.setSize(mt.length);
        java.util.zip.CRC32 crc = new java.util.zip.CRC32();
        crc.update(mt);
        mtEntry.setCrc(crc.getValue());
        zos.putNextEntry(mtEntry);
        zos.write(mt);
        zos.closeEntry();
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
