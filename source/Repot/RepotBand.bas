B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'A positioned band: a section after style resolution, grid normalisation,
'auto-grow, push-down and height calculation. Coordinates are relative to
'the band's top-left; pagination adds the page offset later.
Sub Class_Globals
	Public Section As RepotSection
	Public X As Double
	Public Y As Double
	Public Width As Double
	Public Height As Double
	Public MinHeight As Double
	Public Elements As List
End Sub

Public Sub Initialize
	Section = Null
	X = 0
	Y = 0
	Width = 0
	Height = 0
	MinHeight = 0
	Elements.Initialize
End Sub

Public Sub Bottom As Double
	Return Y + Height
End Sub
