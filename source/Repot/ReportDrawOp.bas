B4J=true
Group=Render
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'One resolved drawing operation in the render document.
'
'An operation is deliberately flat: exporters switch on OpType rather than
'on a class hierarchy, and the canonical golden writer can serialise one
'shape without reflection. Unused fields keep their initial values.
'
'Geometry is in points. Page layout rounds coordinates to 0.01 pt when it
'calls ReportRenderPage.Add*, so exporters never see measurement precision.
'OpType values: text, image, line, rect, clip, restore, link.
Sub Class_Globals
	Public OpType As String
	Public X As Double
	Public Y As Double
	Public Width As Double
	Public Height As Double
	Public X2 As Double
	Public Y2 As Double
	Public Baseline As Double
	Public Text As String
	Public FontName As String
	Public FontSize As Double
	Public Bold As Boolean
	Public Italic As Boolean
	Public Underline As Boolean
	Public Colour As String
	Public Align As String
	Public FillColour As String
	Public LineWidth As Double
	Public Dash As String
	Public Radius As Double
	Public ResourcePath As String
	Public PixelWidth As Int
	Public PixelHeight As Int
	Public Dpi As Double
	Public Fit As String
	Public Url As String
	Public AnchorName As String
	Public Handle As Object
End Sub

Public Sub Initialize
	OpType = ""
	X = 0
	Y = 0
	Width = 0
	Height = 0
	X2 = 0
	Y2 = 0
	Baseline = 0
	Text = ""
	FontName = ""
	FontSize = 0
	Bold = False
	Italic = False
	Underline = False
	Colour = ""
	Align = "left"
	FillColour = ""
	LineWidth = 0
	Dash = ""
	Radius = 0
	ResourcePath = ""
	PixelWidth = 0
	PixelHeight = 0
	Dpi = 0
	Fit = "contain"
	Url = ""
	AnchorName = ""
	Handle = Null
End Sub
