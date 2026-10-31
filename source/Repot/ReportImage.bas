B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Intrinsic image metadata returned by the adapter. Handle is opaque and
'may be Null; PixelWidth and PixelHeight are the image's own pixels.
Sub Class_Globals
	Public Path As String
	Public PixelWidth As Int
	Public PixelHeight As Int
	Public Dpi As Double
	Public Handle As Object
End Sub

Public Sub Initialize
	Path = ""
	PixelWidth = 0
	PixelHeight = 0
	Dpi = 0
	Handle = Null
End Sub
