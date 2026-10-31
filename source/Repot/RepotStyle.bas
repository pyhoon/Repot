B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Named text style. A zero Size means "inherit the font size".
Sub Class_Globals
	Public Name As String
Public FontName As String
Public Size As Double
Public Bold As Boolean
Public Italic As Boolean
Public Underline As Boolean
Public Colour As String
Public Align As String
Public Valign As String
Public LineSpacing As Double
Public Overflow As String
Public PaddingTop As Double
Public PaddingRight As Double
Public PaddingBottom As Double
Public PaddingLeft As Double
Public HasBorder As Boolean
Public BorderWidth As Double
Public BorderColour As String
Public FillColour As String
Public FormatMap As Map
End Sub

Public Sub Initialize
	Name = ""
	FontName = ""
	Size = 0
	Bold = False
	Italic = False
	Underline = False
	Colour = ""
	Align = "left"
	Valign = "top"
	LineSpacing = 1.2
	Overflow = "grow"
	PaddingTop = 0
	PaddingRight = 0
	PaddingBottom = 0
	PaddingLeft = 0
	HasBorder = False
	BorderWidth = 0
	BorderColour = ""
	FillColour = ""
	FormatMap.Initialize
End Sub
