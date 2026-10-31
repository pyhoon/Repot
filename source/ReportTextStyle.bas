B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Resolved text style used for measurement and layout.
'
'The template's font and style definitions are flattened into this object
'before measurement. Family is the declared fallback order, outermost
'first. Size is in points. LineSpacing multiplies the font size to give a
'nominal line height; it is deliberately independent of platform metrics.
Sub Class_Globals
	Public Family As List
	Public Size As Double
	Public Bold As Boolean
	Public Italic As Boolean
	Public Underline As Boolean
	Public LineSpacing As Double
	Public Colour As String
End Sub

Public Sub Initialize
	Family.Initialize
	Size = 10
	Bold = False
	Italic = False
	Underline = False
	LineSpacing = 1.2
	Colour = "#000000"
End Sub

'Replaces the fallback list with a single requested family.
Public Sub SetFamily (Name As String)
	Family.Clear
	Dim n As String = Name.Trim
	If n.Length > 0 Then Family.Add(n)
End Sub

'Copies this style. The family list is duplicated so callers cannot
'mutate a shared style through an alias.
Public Sub Copy As ReportTextStyle
	Dim s As ReportTextStyle
	s.Initialize
	For Each f As String In Family
		s.Family.Add(f)
	Next
	s.Size = Size
	s.Bold = Bold
	s.Italic = Italic
	s.Underline = Underline
	s.LineSpacing = LineSpacing
	s.Colour = Colour
	Return s
End Sub
