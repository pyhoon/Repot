import org.apache.fontbox.ttf.TTFParser;
import org.apache.fontbox.ttf.TTFSubsetter;
import org.apache.fontbox.ttf.TrueTypeFont;
import org.apache.fontbox.ttf.CmapLookup;
import org.apache.pdfbox.io.RandomAccessReadBufferedFile;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;
import java.util.TreeSet;

/**
 * Builds the multilang fixture font subsets: reads the fixture text files,
 * collects every unique codepoint, and emits a subset TTF containing only
 * the codepoints the source font covers (optionally restricted to a range).
 *
 * args: <in.ttf> <out.ttf> <charsfile> [mode: sc|kr]
 *   sc = everything the cmap covers except hangul
 *   kr = hangul syllables + jamo only
 */
public class SubsetTool {
    public static void main(String[] args) throws Exception {
        File in = new File(args[0]);
        File out = new File(args[1]);
        String mode = args.length > 3 ? args[3] : "sc";

        // collect codepoints from the fixture files
        Set<Integer> wanted = new TreeSet<Integer>();
        StringBuilder text = new StringBuilder();
        for (int i = 2; i < args.length - (args.length > 3 ? 1 : 0); i++) {
            FileInputStream fis = new FileInputStream(args[i]);
            InputStreamReader r = new InputStreamReader(fis, StandardCharsets.UTF_8);
            int c;
            while ((c = r.read()) >= 0) text.append((char) c);
            r.close();
        }
        for (int i = 0; i < text.length(); ) {
            int cp = text.codePointAt(i);
            wanted.add(cp);
            i += Character.charCount(cp);
        }
        // printable ASCII as a safety net for headers/labels
        for (int cp = 0x20; cp <= 0x7E; cp++) wanted.add(cp);

        TrueTypeFont ttf = new TTFParser().parse(new RandomAccessReadBufferedFile(in));
        try {
            CmapLookup cmap = ttf.getUnicodeCmapLookup();
            Set<Integer> glyphs = new HashSet<Integer>();
            for (int cp : wanted) {
                boolean hangul = (cp >= 0xAC00 && cp <= 0xD7AF) || (cp >= 0x1100 && cp <= 0x11FF);
                if (mode.equals("kr") && !hangul) continue;
                if (mode.equals("sc") && hangul) continue;
                if (cmap.getGlyphId(cp) > 0) glyphs.add(cp);
            }
            System.out.println(mode + ": " + glyphs.size() + " covered codepoints of "
                + wanted.size() + " requested");
            TTFSubsetter sub = new TTFSubsetter(ttf);
            sub.addAll(glyphs);
            OutputStream os = new FileOutputStream(out);
            sub.writeToStream(os);
            os.close();
        } finally {
            ttf.close();
        }
        System.out.println("wrote " + out + " (" + out.length() + " bytes)");
    }
}
