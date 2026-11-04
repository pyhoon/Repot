import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import java.io.File;
import java.io.PrintStream;

/**
 * Prints PDFTextStripper extraction of every codepoint with U+xxxx labels.
 *
 * Purpose (Repot M12): shows what ReportPdfExporter.ExtractText returns.
 * Note that PDFBox restores logical order for RTL spans and normalises
 * Arabic presentation forms (U+FE70-FEFF) back to base letters (U+06xx),
 * so this view is the *reading* view, not the drawing view. Use DumpCodes
 * to see what was painted.
 */
public class DumpPdf {
    public static void main(String[] args) throws Exception {
        PrintStream utf = new PrintStream(System.out, true, "UTF-8");
        System.setOut(utf);
        PDDocument doc = Loader.loadPDF(new File(args[0]));
        PDFTextStripper st = new PDFTextStripper();
        String txt = st.getText(doc);
        System.out.println("EXTRACT (pdfbox normalised):");
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < txt.length(); i++) {
            int cp = txt.codePointAt(i);
            sb.append("U+").append(Integer.toHexString(cp).toUpperCase()).append(' ');
            if (sb.length() > 60) { System.out.println(sb); sb.setLength(0); }
        }
        System.out.println(sb);
        doc.close();
    }
}
