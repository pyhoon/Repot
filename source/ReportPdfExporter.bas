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
	'Optional TrueType fonts to embed (empty = Standard 14, Latin-1 only).
	'FontFile/FontFileBold are the primary pair; additional pairs can be
	'registered with AddEmbeddedFont (v1.4) for mixed-script exports.
	Public FontFile As String
	Public FontFileBold As String
	'Paragraph base direction for the bidi pass: "ltr" (default) or "rtl".
	Public BaseDirection As String
	Private mDoc As ReportRenderDocument
	Private mOutPath As String
	Private mJavaDoc As Object
	Private mPageHeight As Double
	Private mExtraFonts As List
End Sub

Public Sub Initialize (Diags As ReportDiagnostics)
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As ReportDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
	SourceDir = ""
	FontFile = ""
	FontFileBold = ""
	BaseDirection = "ltr"
	mExtraFonts.Initialize
End Sub

'Registers an additional embedded font pair for mixed-script exports.
'The primary FontFile/FontFileBold pair is probed first; pairs are
'tried in registration order. Call before Export.
Public Sub AddEmbeddedFont (RegularPath As String, BoldPath As String)
	mExtraFonts.Add(Array(RegularPath, BoldPath))
End Sub

Public Sub Export (Doc As ReportRenderDocument, OutputPath As String) As Boolean
	mDoc = Doc
	mOutPath = OutputPath
	#If B4A
	'Android uses the vector canvas path (Printing library) instead of PDFBox.
	Return ReportB4APrint.PrintVectorPdf(Doc, OutputPath, SourceDir)
	#Else
	Dim jo As JavaObject
	jo.InitializeStatic("b4j.example.reportpdfexporter")

	Try
		mJavaDoc = jo.RunMethod("createDocument", Null)
		If FontFile <> "" Then
			jo.RunMethod("loadFonts", Array(mJavaDoc, FontFile, FontFileBold))
		End If
		Dim i As Int
		jo.RunMethod("setBaseRTL", Array(BaseDirection <> Null And BaseDirection.ToLowerCase = "rtl"))
		For i = 0 To mExtraFonts.Size - 1
			Dim pair() As Object = mExtraFonts.Get(i)
			jo.RunMethod("addFontPair", Array(mJavaDoc, pair(0), pair(1)))
		Next
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
	#End If
End Sub

Private Sub DrawOp (jo As JavaObject, cs As Object, op As ReportDrawOp)
	Select Case op.OpType
		Case "text"
			Dim font As Object = jo.RunMethod("resolveFont", Array(op.FontName, op.Bold, op.Italic))
			Dim pdfBaseline As Double = mPageHeight - op.Y - op.Baseline
			jo.RunMethod("drawText", Array(cs, font, op.FontSize, op.X, pdfBaseline, op.Text, op.Colour, op.Align, op.Width, op.Bold))
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
	#Else
	Try
		Dim jo As JavaObject
		jo.InitializeStatic("b4j.example.reportpdfexporter")
		Return jo.RunMethod("pageCount", Array(Path))
	Catch
		'Introspection returns 0 for unreadable or missing files; the
		'export path reports its own diagnostics separately.
		Return 0
	End Try
	#End If
End Sub

Public Sub ExtractText (Path As String) As String
	#If B4A
	Return ""
	#Else
	Try
		Dim jo As JavaObject
		jo.InitializeStatic("b4j.example.reportpdfexporter")
		Return jo.RunMethod("extractText", Array(Path))
	Catch
		'See PageCount; unreadable files yield "".
		Return ""
	End Try
	#End If
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
    java.io.File f = new java.io.File(path);
    if (f.exists()) f.delete();
    ((PDDocument)doc).save(path);
}

private static org.apache.pdfbox.pdmodel.font.PDType0Font sRegular = null;
private static org.apache.pdfbox.pdmodel.font.PDType0Font sBold = null;
/*
 * Ordered embedded font pairs (v1.4): each entry is
 * {regularFont, boldFont} with null for a missing variant. The primary
 * FontFile/FontFileBold pair is registered first; AddEmbeddedFont
 * appends. drawText walks the list to split a visual string into
 * per-font runs so mixed-script lines draw with the right glyphs.
 */
private static java.util.List<org.apache.pdfbox.pdmodel.font.PDType0Font[]> sPairs =
    new java.util.ArrayList<org.apache.pdfbox.pdmodel.font.PDType0Font[]>();
/* Per (font, codepoint) coverage cache; encode() throws when uncovered. */
private static java.util.Map<org.apache.pdfbox.pdmodel.font.PDType0Font, java.util.Map<Integer, Boolean>> sCoverage =
    new java.util.IdentityHashMap<org.apache.pdfbox.pdmodel.font.PDType0Font, java.util.Map<Integer, Boolean>>();
/* Paragraph base direction for the bidi pass (set per export). */
private static boolean sBaseRTL = false;

public static void setBaseRTL(boolean rtl) {
    sBaseRTL = rtl;
}

public static void loadFonts(Object doc, String regular, String bold) throws Exception {
    PDDocument d = (PDDocument)doc;
    sRegular = null;
    sBold = null;
    sPairs = new java.util.ArrayList<org.apache.pdfbox.pdmodel.font.PDType0Font[]>();
    sCoverage = new java.util.IdentityHashMap<org.apache.pdfbox.pdmodel.font.PDType0Font, java.util.Map<Integer, Boolean>>();
    addFontPair(d, regular, bold);
    if (!sPairs.isEmpty()) {
        sRegular = sPairs.get(0)[0];
        sBold = sPairs.get(0)[1];
    }
}

/*
 * Loads one regular/bold pair and appends it to the set. Null or empty
 * paths skip the variant. Called for the primary pair by loadFonts and
 * once per AddEmbeddedFont registration by Export.
 */
public static void addFontPair(Object doc, String regular, String bold) throws Exception {
    PDDocument d = (PDDocument)doc;
    org.apache.pdfbox.pdmodel.font.PDType0Font r = null;
    org.apache.pdfbox.pdmodel.font.PDType0Font b = null;
    if (regular != null && regular.length() > 0) {
        r = org.apache.pdfbox.pdmodel.font.PDType0Font.load(d, new File(regular));
    }
    if (bold != null && bold.length() > 0) {
        b = org.apache.pdfbox.pdmodel.font.PDType0Font.load(d, new File(bold));
    }
    if (r != null || b != null) {
        sPairs.add(new org.apache.pdfbox.pdmodel.font.PDType0Font[] { r, b });
    }
}

public static void close(Object doc) throws Exception {
    ((PDDocument)doc).close();
    sRegular = null;
    sBold = null;
    sPairs = new java.util.ArrayList<org.apache.pdfbox.pdmodel.font.PDType0Font[]>();
    sCoverage = new java.util.IdentityHashMap<org.apache.pdfbox.pdmodel.font.PDType0Font, java.util.Map<Integer, Boolean>>();
    sBaseRTL = false;
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
    if (sRegular != null) {
        return (bold && sBold != null) ? sBold : sRegular;
    }
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

private static String safeText(PDFont font, String text) {
    if (text == null) return "";
    if (!(font instanceof org.apache.pdfbox.pdmodel.font.PDType0Font)) return text;
    org.apache.pdfbox.pdmodel.font.PDType0Font f = (org.apache.pdfbox.pdmodel.font.PDType0Font)font;
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < text.length(); ) {
        int cp = text.codePointAt(i);
        i += Character.charCount(cp);
        String ch = new String(Character.toChars(cp));
        try {
            f.encode(ch);
            sb.append(ch);
        } catch (Exception e) {
            sb.append('?');
        }
    }
    return sb.toString();
}

public static void drawText(Object cs, Object font, double size, double x, double y, String text, String colour, String align, double boxWidth, boolean bold) throws Exception {
    PDPageContentStream s = (PDPageContentStream)cs;
    // Bidi + Arabic presentation-form shaping: PDF text streams have no
    // shaping engine of their own, so the logical-order string is first
    // shaped (Arabic contextual forms, lam-alef) and then chunked into
    // bidi runs and emitted in visual order. Latin-only strings pass
    // through unchanged.
    String visual = bidiVisual(text, sBaseRTL);
    // Split into maximal runs by which embedded font covers them (v1.4
    // font set). With no embedded fonts (or a single covering font) this
    // is one run and the code path is identical to v1.3.
    java.util.List<Object[]> runs = splitRuns(visual, (PDFont)font, bold);
    // Alignment width: sum of the run widths measured with their own
    // fonts, so right/center anchors stay on the real PDF width.
    float textWidth = 0f;
    for (Object[] run : runs) {
        PDFont f = (PDFont)run[0];
        String safe = safeText(f, (String)run[1]);
        if (safe.length() == 0) continue;
        try {
            textWidth += f.getStringWidth(safe) / 1000f * (float)size;
        } catch (Exception ignored) {
            // unmeasurable run contributes nothing to the anchor
        }
    }
    float drawX = (float)x;
    if (align != null && align.length() > 0) {
        if (align.equalsIgnoreCase("right")) {
            drawX = (float)(x + boxWidth - textWidth);
        } else if (align.equalsIgnoreCase("center")) {
            drawX = (float)(x + (boxWidth - textWidth) / 2.0);
        }
    }
    float cursor = drawX;
    for (Object[] run : runs) {
        PDFont f = (PDFont)run[0];
        String safe = safeText(f, (String)run[1]);
        if (safe.length() == 0) continue;
        s.beginText();
        s.setFont(f, (float)size);
        s.newLineAtOffset(cursor, (float)y);
        s.showText(safe);
        s.endText();
        try {
            cursor += f.getStringWidth(safe) / 1000f * (float)size;
        } catch (Exception ignored) {
            // keep the cursor moving even if a run cannot be measured
        }
    }
}

/*
 * Splits a visual-order string into maximal runs drawn with one font
 * each. Candidate fonts are the embedded pairs in registration order
 * (bold ops prefer each pair's bold variant, falling back to its
 * regular); the first font whose cmap covers the codepoint wins. A run
 * no embedded font covers falls back to the caller's resolved font
 * (primary embedded pair, or a Standard 14 font), where safeText's '?'
 * substitution applies exactly as before.
 */
private static java.util.List<Object[]> splitRuns(String text, PDFont fallback, boolean bold) {
    java.util.List<Object[]> out = new java.util.ArrayList<Object[]>();
    if (text == null || text.isEmpty()) return out;
    int i = 0;
    int n = text.length();
    while (i < n) {
        int cp = text.codePointAt(i);
        PDFont f = pickFont(cp, bold);
        int j;
        if (f == null) {
            // uncovered: batch until the next covered codepoint
            j = i + Character.charCount(cp);
            while (j < n && pickFont(text.codePointAt(j), bold) == null) {
                j += Character.charCount(text.codePointAt(j));
            }
            out.add(new Object[] { fallback, text.substring(i, j) });
        } else {
            j = i + Character.charCount(cp);
            while (j < n) {
                PDFont f2 = pickFont(text.codePointAt(j), bold);
                if (f2 != f) break;
                j += Character.charCount(text.codePointAt(j));
            }
            out.add(new Object[] { f, text.substring(i, j) });
        }
        i = j;
    }
    return out;
}

/* First embedded font covering the codepoint, or null. Cached per font. */
private static PDFont pickFont(int cp, boolean bold) {
    for (org.apache.pdfbox.pdmodel.font.PDType0Font[] pair : sPairs) {
        org.apache.pdfbox.pdmodel.font.PDType0Font f =
            (bold && pair[1] != null) ? pair[1] : pair[0];
        if (f == null) continue;
        if (covers(f, cp)) return f;
    }
    return null;
}

private static boolean covers(org.apache.pdfbox.pdmodel.font.PDType0Font f, int cp) {
    java.util.Map<Integer, Boolean> m = sCoverage.get(f);
    if (m == null) {
        m = new java.util.HashMap<Integer, Boolean>();
        sCoverage.put(f, m);
    }
    Boolean cached = m.get(Integer.valueOf(cp));
    if (cached != null) return cached.booleanValue();
    boolean ok;
    try {
        f.encode(new String(Character.toChars(cp)));
        ok = true;
    } catch (Exception e) {
        ok = false;
    }
    m.put(Integer.valueOf(cp), Boolean.valueOf(ok));
    return ok;
}

/*
 * Arabic presentation-form shaping table (Unicode Arabic Forms-B,
 * U+FE70-FEFF) with mandatory lam-alef ligatures. Compiled per request:
 * for each letter, {isolated, final, initial, medial}; -1 = form does
 * not exist (non-joining letters have no initial/medial forms).
 * This is the classic shaping approach used before HarfBuzz-era
 * engines; it covers correct contextual forms for all 36 standard
 * Arabic letters. Presentation forms are emitted as normal Unicode
 * codepoints through PDFont.encode, so PDFBox subsetting and the
 * ToUnicode CMap keep working (extractable text).
 * Verified: Noto Sans Arabic maps 140/144 of U+FE70-FEFF (the four
 * gaps are unused variation-selector positions) and all lam-alef
 * ligatures.
 */
private static int[][] ARABIC_FORMS = new int[0x0700][];

private static void setForms(int base, int i, int f, int ini, int m) {
    ARABIC_FORMS[base] = new int[] { i, f, ini, m };
}

private static void buildArabicForms() {
    setForms(0x0621, 0xFE80, -1, -1, -1);        // HAMZA
    setForms(0x0622, 0xFE81, 0xFE82, -1, -1);    // ALEF MADDA
    setForms(0x0623, 0xFE83, 0xFE84, -1, -1);    // ALEF HAMZA ABOVE
    setForms(0x0624, 0xFE85, 0xFE86, -1, -1);    // WAW HAMZA
    setForms(0x0625, 0xFE87, 0xFE88, -1, -1);    // ALEF HAMZA BELOW
    setForms(0x0626, 0xFE89, 0xFE8A, 0xFE8B, 0xFE8C); // YEH HAMZA
    setForms(0x0627, 0xFE8D, 0xFE8E, -1, -1);    // ALEF
    setForms(0x0628, 0xFE8F, 0xFE90, 0xFE91, 0xFE92); // BEH
    setForms(0x0629, 0xFE93, 0xFE94, -1, -1);    // TEH MARBUTA
    setForms(0x062A, 0xFE95, 0xFE96, 0xFE97, 0xFE98); // TEH
    setForms(0x062B, 0xFE99, 0xFE9A, 0xFE9B, 0xFE9C); // THEH
    setForms(0x062C, 0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0); // JEEM
    setForms(0x062D, 0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4); // HAH
    setForms(0x062E, 0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8); // KHAH
    setForms(0x062F, 0xFEA9, 0xFEAA, -1, -1);    // DAL
    setForms(0x0630, 0xFEAB, 0xFEAC, -1, -1);    // THAL
    setForms(0x0631, 0xFEAD, 0xFEAE, -1, -1);    // REH
    setForms(0x0632, 0xFEAF, 0xFEB0, -1, -1);    // ZAIN
    setForms(0x0633, 0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4); // SEEN
    setForms(0x0634, 0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8); // SHEEN
    setForms(0x0635, 0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC); // SAD
    setForms(0x0636, 0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0); // DAD
    setForms(0x0637, 0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4); // TAH
    setForms(0x0638, 0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8); // ZAH
    setForms(0x0639, 0xFEC9, 0xFECA, 0xFECB, 0xFECC); // AIN
    setForms(0x063A, 0xFECD, 0xFECE, 0xFECF, 0xFED0); // GHAIN
    setForms(0x0641, 0xFED1, 0xFED2, 0xFED3, 0xFED4); // FEH
    setForms(0x0642, 0xFED5, 0xFED6, 0xFED7, 0xFED8); // QAF
    setForms(0x0643, 0xFED9, 0xFEDA, 0xFEDB, 0xFEDC); // KAF
    setForms(0x0644, 0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0); // LAM
    setForms(0x0645, 0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4); // MEEM
    setForms(0x0646, 0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8); // NOON
    setForms(0x0647, 0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC); // HEH
    setForms(0x0648, 0xFEED, 0xFEEE, -1, -1);    // WAW
    setForms(0x0649, 0xFEEF, 0xFEF0, -1, -1);    // ALEF MAKSURA
    setForms(0x064A, 0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4); // YEH
}

private static boolean arabicLetter(int cp) {
    return cp >= 0x0621 && cp <= 0x064A;
}

// Letters that never join to the following letter (logical next).
private static boolean nonJoining(int cp) {
    return cp == 0x0621 || cp == 0x0622 || cp == 0x0623 || cp == 0x0624
        || cp == 0x0625 || cp == 0x0627 || cp == 0x0629 || cp == 0x062F
        || cp == 0x0630 || cp == 0x0631 || cp == 0x0632 || cp == 0x0648;
}

/*
 * Shapes an Arabic logical-order string into presentation forms.
 * Context spans the whole string; neighbours that are Arabic letters
 * propose joining. Lam + one of the ALEF variants collapses into the
 * mandatory ligature (isolated or final form). Tatweel (U+0640) passes
 * through and sustains joins. Nothing else is touched, so Latin, digits
 * and punctuation are unchanged.
 */
public static String shapeArabic(String text) {
    if (text == null || text.isEmpty()) return text;
    boolean hasArabic = false;
    for (int i = 0; i < text.length(); i++) {
        if (arabicLetter(text.charAt(i))) { hasArabic = true; break; }
    }
    if (!hasArabic) return text;
    buildArabicForms();
    int n = text.length();
    StringBuilder out = new StringBuilder(n + 8);
    for (int i = 0; i < n; i++) {
        int cp = text.codePointAt(i);
        if (!arabicLetter(cp) && cp != 0x0640) { out.appendCodePoint(cp); continue; }
        // previous strong-Arabic letter (skipping non-letters) proposes a join from the right
        boolean joinedFromRight = false;
        for (int j = i - 1; j >= 0; j--) {
            int pj = text.codePointAt(j);
            if (pj == 0x0640) { joinedFromRight = true; break; }  // tatweel sustains the connection
            if (isSpaceLike(pj)) break;                          // whitespace breaks joining
            if (arabicLetter(pj)) { joinedFromRight = !nonJoining(pj); break; }
            break;                                                // any other glyph breaks joining
        }
        // next letter proposes a join from the left (I must be a joining letter)
        boolean joinsNext = false;
        int ncp = 0, ni = -1;
        if (cp != 0x0640 && i < n - 1) {
            int k = i + 1;
            ncp = text.codePointAt(k);
            ni = k;
        }
        int[] forms = (cp >= 0x0621 && cp <= 0x064A) ? ARABIC_FORMS[cp] : null;
        // lam-alef mandatory ligature
        if (cp == 0x0644 && (ncp == 0x0622 || ncp == 0x0623 || ncp == 0x0625 || ncp == 0x0627)) {
            int lig = ncp == 0x0622 ? 0xFEF5 : ncp == 0x0623 ? 0xFEF7 : ncp == 0x0625 ? 0xFEF9 : 0xFEFB;
            out.appendCodePoint(lig + (joinedFromRight ? 1 : 0));
            i = ni; // consume the alef too
            continue;
        }
        if (forms == null) { out.appendCodePoint(cp); continue; } // tatweel or unmapped
        boolean iJoinNext = !(nonJoining(cp));
        int form;
        if (joinedFromRight && iJoinNext && arabicJoiner(ncp)) form = forms[3]; // medial: joined from both sides
        else if (joinedFromRight) form = forms[1];             // final
        else if (iJoinNext && arabicJoiner(ncp)) form = forms[2]; // initial
        else form = forms[0];                                  // isolated
        int chosen = form >= 0 ? form : forms[0];
        out.appendCodePoint(chosen);
    }
    return out.toString();
}

private static boolean arabicJoiner(int cp) {
    return arabicLetter(cp) || cp == 0x0640;
}

private static boolean isSpaceLike(int cp) {
    return cp == ' ' || cp == '\t' || cp == '\n' || cp == '\r';
}

/*
 * Bidi pass: chunk the string into unicode bidi runs and arrange them in
 * visual order. Odd-level chunks (true RTL) are codepoint-reversed so
 * PDFBox, which paints left to right, produces the correct glyph order.
 * Bidi.reorderVisually handles nested levels (digits inside Arabic run
 * at a deeper even level stay LTR). The base direction comes from the
 * exporter's BaseDirection property ("ltr" default, "rtl" supported):
 * with an RTL base a pure-RTL line stays one level-1 run, so trailing
 * neutral punctuation lands on the left edge as an RTL reader expects.
 */
public static String bidiVisual(String text, boolean rtlBase) {
    if (text == null || text.isEmpty()) return text;
    try {
        // Shape first, over the full logical string so joining context is
        // complete (lam-alef collapses two codepoints into one). The bidi
        // run boundaries of the shaped string are the same: presentation
        // forms carry RTL direction just like their base letters.
        String shaped = shapeArabic(text);
        int direction = rtlBase ? java.text.Bidi.DIRECTION_RIGHT_TO_LEFT
                                : java.text.Bidi.DIRECTION_LEFT_TO_RIGHT;
        java.text.Bidi bidi = new java.text.Bidi(shaped, direction);
        int runs = bidi.getRunCount();
        if (runs <= 1 && bidi.getRunLevel(0) == 0) return shaped;
        byte[] levels = new byte[runs];
        Object[] items = new Object[runs];
        for (int r = 0; r < runs; r++) {
            levels[r] = (byte) bidi.getRunLevel(r);
            items[r] = new Object[] { Integer.valueOf(r), shaped.substring(bidi.getRunStart(r), bidi.getRunLimit(r)) };
        }
        // Bidi.reorderVisually reorders the array in place (returns void)
        java.text.Bidi.reorderVisually(levels, 0, items, 0, items.length);
        Object[] visual = items;
        StringBuilder out = new StringBuilder(text.length());
        for (Object o : visual) {
            Object[] pair = (Object[]) o;
            int idx = ((Integer) pair[0]).intValue();
            byte lvl = levels[idx];
            String chunk = ((String) pair[1]);
            if ((lvl & 1) == 1) {
                // RTL chunk: shape happens before reversal in the logical string,
                // so reverse now for left-to-right painting
                int[] cps = chunk.codePoints().toArray();
                int from = 0, to = cps.length - 1;
                while (from < to) {
                    int t = cps[from]; cps[from] = cps[to]; cps[to] = t;
                    from++; to--;
                }
                StringBuilder rev = new StringBuilder(cps.length);
                for (int c : cps) rev.appendCodePoint(c);
                out.append(rev);
            } else {
                out.append(chunk);
            }
        }
        return out.toString();
    } catch (Throwable t) {
        return shapeArabic(text == null ? "" : text);
    }
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
