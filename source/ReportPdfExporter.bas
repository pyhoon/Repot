B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'PDF exporter for B4J using Apache PDFBox 3.0. Built on the render
'document; it never re-measures or re-evaluates expressions.

Sub Class_Globals
	Public Diagnostics As ReportDiagnostics
	Public SourceDir As String
	Private mDoc As ReportRenderDocument
	Private mOutPath As String
	Private mJavaDoc As Object
	Private mPageHeight As Double
End Sub

Public Sub Initialize (Diags As ReportDiagnostics)
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
	SourceDir = ""
End Sub

Public Sub Export (Doc As ReportRenderDocument, OutputPath As String) As Boolean
	mDoc = Doc
	mOutPath = OutputPath
	#If B4A
	'PDFBox is a desktop (JVM) library and is not available on Android.
	'Record a clear diagnostic instead of a reflection crash.
	Diagnostics.AddError("E-PDF-001", "PDF export is not available on this platform; the PDFBox renderer runs on B4J only", "")
	Return False
	#End If
	Dim jo As JavaObject
	jo.InitializeStatic("b4j.example.reportpdfexporter")

	Try
		mJavaDoc = jo.RunMethod("createDocument", Null)
		Dim i As Int
		For i = 0 To Doc.PageCount - 1
			Dim page As ReportRenderPage = Doc.PageAt(i + 1)
			mPageHeight = page.Height
			Dim jpage As Object = jo.RunMethod("addPage", Array(mJavaDoc, page.Width, page.Height))
			Dim cs As Object = jo.RunMethod("beginContent", Array(mJavaDoc, jpage))
			Dim k As Int
			For k = 0 To page.Ops.Size - 1
				Dim op As ReportDrawOp = page.Ops.Get(k)
				DrawOp(jo, cs, op)
			Next
			jo.RunMethod("closeContent", Array(cs))
		Next
		jo.RunMethod("save", Array(mJavaDoc, mOutPath))
		jo.RunMethod("close", Array(mJavaDoc))
		Return True
	Catch
		Log(LastException.Message)
		Diagnostics.AddError("E-PDF-001", "PDF export failed: " & LastException.Message, "")
		Try
			jo.RunMethod("close", Array(mJavaDoc))
		Catch
			Log(LastException.Message)
		End Try
		Return False
	End Try
End Sub

Private Sub DrawOp (jo As JavaObject, cs As Object, op As ReportDrawOp)
	Select Case op.OpType
		Case "text"
			Dim font As Object = jo.RunMethod("resolveFont", Array(op.FontName, op.Bold, op.Italic))
			Dim pdfBaseline As Double = mPageHeight - op.Y - op.Baseline
			jo.RunMethod("drawText", Array(cs, font, op.FontSize, op.X, pdfBaseline, op.Text, op.Colour))
		Case "image"
			Dim pdfY As Double = mPageHeight - op.Y - op.Height
			jo.RunMethod("drawImage", Array(cs, mJavaDoc, op.ResourcePath, op.X, pdfY, op.Width, op.Height, op.Fit, SourceDir))
		Case "line"
			Dim y1 As Double = mPageHeight - op.Y
			Dim y2 As Double = mPageHeight - op.Y2
			jo.RunMethod("drawLine", Array(cs, op.X, y1, op.X2, y2, op.LineWidth, op.Colour, op.Dash))
		Case "rect"
			Dim ry As Double = mPageHeight - op.Y - op.Height
			jo.RunMethod("drawRect", Array(cs, op.X, ry, op.Width, op.Height, op.LineWidth, op.Colour, op.FillColour, op.Radius))
		Case "clip"
			Dim cy As Double = mPageHeight - op.Y - op.Height
			jo.RunMethod("clip", Array(cs, op.X, cy, op.Width, op.Height))
		Case "restore"
			jo.RunMethod("restore", Array(cs))
		Case "link"
			' no visual
	End Select
End Sub

Public Sub PageCount (Path As String) As Int
	#If B4A
	Return 0
	#End If
	Dim jo As JavaObject
	jo.InitializeStatic("b4j.example.reportpdfexporter")
	Return jo.RunMethod("pageCount", Array(Path))
End Sub

Public Sub ExtractText (Path As String) As String
	#If B4A
	Return ""
	#End If
	Dim jo As JavaObject
	jo.InitializeStatic("b4j.example.reportpdfexporter")
	Return jo.RunMethod("extractText", Array(Path))
End Sub

#If B4J
#If Java
import org.apache.pdfbox.pdmodel.*;
import org.apache.pdfbox.pdmodel.common.*;
import org.apache.pdfbox.pdmodel.font.*;
import org.apache.pdfbox.pdmodel.graphics.image.*;
import org.apache.pdfbox.text.*;
import java.io.*;

public static Object createDocument() {
    return new PDDocument();
}

public static Object addPage(Object doc, double w, double h) {
    PDPage page = new PDPage(new PDRectangle((float)w, (float)h));
    ((PDDocument)doc).addPage(page);
    return page;
}

public static Object beginContent(Object doc, Object page) throws Exception {
    return new PDPageContentStream((PDDocument)doc, (PDPage)page);
}

public static void closeContent(Object cs) throws Exception {
    ((PDPageContentStream)cs).close();
}

public static void save(Object doc, String path) throws Exception {
    ((PDDocument)doc).save(path);
}

public static void close(Object doc) throws Exception {
    ((PDDocument)doc).close();
}

public static int pageCount(String path) throws Exception {
    PDDocument d = org.apache.pdfbox.Loader.loadPDF(new File(path));
    int n = d.getNumberOfPages();
    d.close();
    return n;
}

public static String extractText(String path) throws Exception {
    PDDocument d = org.apache.pdfbox.Loader.loadPDF(new File(path));
    PDFTextStripper stripper = new PDFTextStripper();
    String t = stripper.getText(d);
    d.close();
    return t;
}

public static Object resolveFont(String family, boolean bold, boolean italic) {
    String f = family == null ? "" : family.toLowerCase();
    boolean serif = f.contains("serif") || f.contains("times");
    boolean mono = f.contains("mono") || f.contains("courier");
    org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName name;
    if (serif) {
        if (bold && italic) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.TIMES_BOLD_ITALIC;
        else if (bold) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.TIMES_BOLD;
        else if (italic) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.TIMES_ITALIC;
        else name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.TIMES_ROMAN;
    } else if (mono) {
        if (bold && italic) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.COURIER_BOLD_OBLIQUE;
        else if (bold) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.COURIER_BOLD;
        else if (italic) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.COURIER_OBLIQUE;
        else name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.COURIER;
    } else {
        if (bold && italic) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.HELVETICA_BOLD_OBLIQUE;
        else if (bold) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.HELVETICA_BOLD;
        else if (italic) name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.HELVETICA_OBLIQUE;
        else name = org.apache.pdfbox.pdmodel.font.Standard14Fonts.FontName.HELVETICA;
    }
    return new org.apache.pdfbox.pdmodel.font.PDType1Font(name);
}

public static void drawText(Object cs, Object font, double size, double x, double y, String text, String colour) throws Exception {
    PDPageContentStream s = (PDPageContentStream)cs;
    s.beginText();
    s.setFont((PDFont)font, (float)size);
    s.newLineAtOffset((float)x, (float)y);
    s.showText(text == null ? "" : text);
    s.endText();
}

public static void drawLine(Object cs, double x1, double y1, double x2, double y2, double lw, String colour, String dash) throws Exception {
    PDPageContentStream s = (PDPageContentStream)cs;
    s.setLineWidth((float)lw);
    s.moveTo((float)x1, (float)y1);
    s.lineTo((float)x2, (float)y2);
    s.stroke();
}

public static void drawRect(Object cs, double x, double y, double w, double h, double lw, String colour, String fill, double radius) throws Exception {
    PDPageContentStream s = (PDPageContentStream)cs;
    if (fill != null && fill.length() > 0) {
        // fill not implemented in v1
    }
    if (lw > 0) {
        s.setLineWidth((float)lw);
        s.addRect((float)x, (float)y, (float)w, (float)h);
        s.stroke();
    }
}

public static void clip(Object cs, double x, double y, double w, double h) throws Exception {
    PDPageContentStream s = (PDPageContentStream)cs;
    s.addRect((float)x, (float)y, (float)w, (float)h);
    s.clip();
}

public static void restore(Object cs) throws Exception {
    // no-op in 3.0 stream API
}

public static void drawImage(Object cs, Object doc, String resourcePath, double x, double y, double w, double h, String fit, String sourceDir) throws Exception {
    if (resourcePath == null || resourcePath.length() == 0) return;
    String path = resourcePath;
    if (sourceDir != null && sourceDir.length() > 0) {
        path = sourceDir + "/" + resourcePath;
    }
    java.io.File f = new java.io.File(path);
    if (!f.exists()) return;
    PDImageXObject img = PDImageXObject.createFromFile(path, (PDDocument)doc);
    PDPageContentStream s = (PDPageContentStream)cs;
    s.drawImage(img, (float)x, (float)y, (float)w, (float)h);
}
#End If
#End If
