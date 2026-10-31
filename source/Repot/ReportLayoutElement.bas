B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'One child of a laid-out band. Bounds are final points. Lines and
'LineWidths come from the measurement adapter and must not be re-wrapped
'by exporters.
Sub Class_Globals
	Public Element As ReportElement
	Public X As Double
	Public Y As Double
	Public Width As Double
	Public Height As Double
	Public DeclaredHeight As Double
	Public Style As ReportTextStyle
	Public Font As ReportFont
	Public Align As String
	Public Valign As String
	Public Overflow As String
	Public Content As String
	Public Lines As List
	Public LineWidths As List
	Public MeasuredHeight As Double
	Public GrowBy As Double
End Sub

Public Sub Initialize
	Element = Null
	X = 0
	Y = 0
	Width = 0
	Height = 0
	DeclaredHeight = 0
	Style = Null
	Font = Null
	Align = "left"
	Valign = "top"
	Overflow = "grow"
	Content = ""
	Lines.Initialize
	LineWidths.Initialize
	MeasuredHeight = 0
	GrowBy = 0
End Sub

Public Sub Right As Double
	Return X + Width
End Sub

Public Sub Bottom As Double
	Return Y + Height
End Sub
