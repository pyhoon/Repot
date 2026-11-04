import java.io.*;
import java.util.*;

/**
 * Lists or strips sfnt tables from a TTF.
 * args: <in.ttf> [out.ttf]  - with out.ttf: copy all tables except
 * variable-font tables (fvar gvar avar HVAR VVAR MVAR STAT).
 */
public class StripVF {
    static final Set<String> DROP = new HashSet<String>(Arrays.asList(
        "fvar", "gvar", "avar", "HVAR", "VVAR", "MVAR", "STAT"));

    public static void main(String[] args) throws Exception {
        RandomAccessFile raf = new RandomAccessFile(args[0], "r");
        int sfnt = raf.readInt();
        int numTables = raf.readUnsignedShort();
        raf.skipBytes(6);
        String[] tags = new String[numTables];
        int[] offs = new int[numTables];
        int[] lens = new int[numTables];
        for (int i = 0; i < numTables; i++) {
            byte[] tb = new byte[4];
            raf.readFully(tb);
            tags[i] = new String(tb, "ISO-8859-1");
            raf.readInt(); // checksum
            offs[i] = raf.readInt();
            lens[i] = raf.readInt();
        }
        for (int i = 0; i < numTables; i++)
            System.out.println(tags[i] + " " + lens[i] + (DROP.contains(tags[i]) ? "  (drop)" : ""));
        if (args.length < 2) { raf.close(); return; }

        // rebuild: keep non-VF tables, 4-byte aligned
        List<String> keep = new ArrayList<String>();
        for (String t : tags) if (!DROP.contains(t)) keep.add(t);
        Collections.sort(keep);
        int n = keep.size();
        int dirSize = 12 + 16 * n;
        int dataOff = dirSize;
        int[] newOffs = new int[n];
        byte[][] datas = new byte[n][];
        for (int i = 0; i < n; i++) {
            int idx = Arrays.asList(tags).indexOf(keep.get(i));
            raf.seek(offs[idx]);
            byte[] d = new byte[lens[idx]];
            raf.readFully(d);
            datas[i] = d;
            newOffs[i] = dataOff;
            dataOff += (lens[idx] + 3) & ~3;
        }
        raf.close();
        RandomAccessFile w = new RandomAccessFile(args[1], "rw");
        w.writeInt(sfnt);
        w.writeShort(n);
        w.writeShort(128); // searchRange (approximate, readers tolerate)
        w.writeShort(3);
        w.writeShort(4);
        for (int i = 0; i < n; i++) {
            w.write(keep.get(i).getBytes("ISO-8859-1"));
            w.writeInt(0); // checksum (readers tolerate 0 for local files)
            w.writeInt(newOffs[i]);
            w.writeInt(datas[i].length);
        }
        for (int i = 0; i < n; i++) {
            w.write(datas[i]);
            while (w.getFilePointer() % 4 != 0) w.write(0);
        }
        w.close();
        System.out.println("wrote " + args[1] + " (" + new File(args[1]).length() + " bytes)");
    }
}
