B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'One drawable element. Bounds are in points relative to the band.
Sub Class_Globals
	Public ElementType As String
Public Id As String
Public X As Double
Public Y As Double
Public Width As Double
Public Height As Double
Public HasBounds As Boolean
Public UseCell As Boolean
Public CellCol As Int
Public CellRow As Int
Public CellColSpan As Int
Public CellRowSpan As Int
Public StyleName As String
Public Align As String
Public Valign As String
Public VisibleExpression As String
Public ZIndex As Int
Public Text As String
Public ValueExpression As String
Public Resource As String
Public Fit As String
Public Dpi As Double
Public LineWidth As Double
Public Colour As String
Public Dash As String
Public FillColour As String
Public Radius As Double
Public FormatMap As Map
Public SourcePath As String
End Sub

Public Sub Initialize
	ElementType = ""
	Id = ""
	X = 0
	Y = 0
	Width = 0
	Height = 0
	HasBounds = False
	UseCell = False
	CellCol = 0
	CellRow = 0
	CellColSpan = 1
	CellRowSpan = 1
	StyleName = ""
	Align = ""
	Valign = ""
	VisibleExpression = ""
	ZIndex = 0
	Text = ""
	ValueExpression = ""
	Resource = ""
	Fit = "contain"
	Dpi = 0
	LineWidth = 0.5
	Colour = ""
	Dash = ""
	FillColour = ""
	Radius = 0
	FormatMap.Initialize
	SourcePath = ""
End Sub

Public Sub Right As Double
	Return X + Width
End Sub

Public Sub Bottom As Double
	Return Y + Height
End Sub
