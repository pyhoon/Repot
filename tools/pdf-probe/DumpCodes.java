import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.cos.COSString;
import org.apache.pdfbox.cos.COSName;
import org.apache.pdfbox.cos.COSBase;
import org.apache.pdfbox.cos.COSArray;
import org.apache.pdfbox.cos.COSDictionary;
import org.apache.pdfbox.pdfparser.PDFStreamParser;
import org.apache.pdfbox.contentstream.operator.Operator;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.PDFontFactory;
import java.io.File;
import java.io.PrintStream;
import java.util.Iterator;

/**
 * Prints every Tj/TJ text-showing operand of the first page decoded through
 * the page font's ToUnicode CMap, in painting order.
 *
 * Purpose (Repot M12): the PDF content stream is the only ground truth for
 * glyph order in RTL text. PDFTextStripper re-normalises RTL spans and
 * Arabic presentation forms back to logical order, so it cannot prove what
 * was drawn. This tool decodes the raw CID codes instead (the dump prints
 * [cNNN?] where a code has no ToUnicode entry, e.g. GID-only or a
 * parity-shifted read).
 *
 * Build / run (JDK 11+):
 *   javac -cp <pdbox-app-3.0.8.jar> DumpCodes.java
 *   java  -cp .;<jar> DumpCodes <pdf file>
 */
public class DumpCodes {
    public static void main(String[] args) throws Exception {
        PrintStream utf = new PrintStream(System.out, true, "UTF-8");
        System.setOut(utf);
        PDDocument doc = Loader.loadPDF(new File(args[0]));
        PDPage page = doc.getPage(0);
        COSDictionary res = page.getResources().getCOSObject();
        COSDictionary fonts = (COSDictionary) res.getDictionaryObject("Font");
        // v1.4: PDFs may carry several font resources (one per embedded
        // pair); Tf selects the active one, so decode through it.
        java.util.Map<String, PDFont> fontCache = new java.util.HashMap<String, PDFont>();
        PDFont active = null;
        PDFStreamParser parser = new PDFStreamParser(page);
        Object token;
        COSString lastStr = null;
        java.util.List<COSBase> operands = new java.util.ArrayList<COSBase>();
        while ((token = parser.parseNextToken()) != null) {
            if (token instanceof Operator) {
                Operator op = (Operator) token;
                if (op.getName().equals("Tf")) {
                    // operands: [fontName, size]
                    if (operands.size() > 0 && operands.get(0) instanceof COSName) {
                        String fname = ((COSName) operands.get(0)).getName();
                        PDFont f = fontCache.get(fname);
                        if (f == null && fonts != null
                                && fonts.getDictionaryObject(fname) instanceof COSDictionary) {
                            f = PDFontFactory.createFont(
                                (COSDictionary) fonts.getDictionaryObject(fname));
                            fontCache.put(fname, f);
                        }
                        active = f;
                    }
                } else if (op.getName().equals("Tj") && lastStr != null) {
                    dumpString(lastStr, active, op.getName());
                    lastStr = null;
                } else if (op.getName().equals("TJ")) {
                    // operands: [array]
                    StringBuilder out = new StringBuilder();
                    for (COSBase o : operands) {
                        if (o instanceof COSArray) {
                            COSArray arr = (COSArray) o;
                            for (int k = 0; k < arr.size(); k++) {
                                COSBase e = arr.get(k);
                                if (e instanceof COSString) {
                                    out.append(decode((COSString) e, active));
                                }
                            }
                        }
                    }
                    System.out.println("TJ [" + fontName(active) + "]: " + out);
                }
                operands.clear();
            } else if (token instanceof COSString) {
                lastStr = (COSString) token;
                operands.add((COSBase) token);
            } else if (token instanceof COSBase) {
                operands.add((COSBase) token);
            }
        }
        doc.close();
    }

    private static String fontName(PDFont f) {
        return f == null ? "?" : f.getName();
    }

    private static void dumpString(COSString s, PDFont font, String name) {
        System.out.println(name + " [" + fontName(font) + "]: " + decode(s, font));
    }

    private static String decode(COSString s, PDFont font) {
        byte[] ds = s.getBytes();
        StringBuilder out = new StringBuilder();
        for (int i = 0; i + 1 < ds.length; i += 2) {
            int code = ((ds[i] & 0xFF) << 8) | (ds[i+1] & 0xFF);
            String uni = font.toUnicode(code);
            if (uni == null) out.append("[c").append(code).append('?').append(']');
            else for (int j = 0; j < uni.length(); j++) out.append("U+").append(Integer.toHexString(uni.charAt(j)).toUpperCase());
            out.append(' ');
        }
        return out.toString();
    }
}
