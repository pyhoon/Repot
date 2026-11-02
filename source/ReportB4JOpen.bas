B4J=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' B4J-only helper: open a file (e.g. a generated PDF) in the default viewer.

#If Java
public static void openPdf(String path) {
    try { java.awt.Desktop.getDesktop().open(new java.io.File(path)); }
    catch (Exception e) { System.out.println("open err: " + e); }
}
#End If

Sub Process_Globals
End Sub

Public Sub OpenPdf(Dir As String, FileName As String)
    Dim jo As JavaObject
    jo.InitializeStatic("b4j.example.reportb4jopen")
    jo.RunMethod("openPdf", Array(Dir & "/" & FileName))
End Sub