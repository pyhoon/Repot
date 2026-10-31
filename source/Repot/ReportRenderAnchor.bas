B4J=true
Group=Render
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'A named position on a page, used by internal links and bookmarks.
'Anchor names are document-unique. Positions are in points.
Sub Class_Globals
	Public Name As String
	Public X As Double
	Public Y As Double
End Sub

Public Sub Initialize
	Name = ""
	X = 0
	Y = 0
End Sub
