B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Result of measuring a text block.
'
'Lines and Widths have one entry per laid-out line. Widths are the
'measured widths of the lines with trailing whitespace removed; Width is
'the widest line. Height is Lines.Size * LineHeight, where LineHeight is
'the nominal style line height, not the platform's line metrics.
'
'Text is already wrapped: layout must not re-wrap these lines.
Sub Class_Globals
	Public Lines As List
	Public Widths As List
	Public Width As Double
	Public Height As Double
	Public Ascent As Double
	Public Descent As Double
	Public LineHeight As Double
	Public Font As ReportFont
End Sub

Public Sub Initialize
	Lines.Initialize
	Widths.Initialize
	Width = 0
	Height = 0
	Ascent = 0
	Descent = 0
	LineHeight = 0
	Font = Null
End Sub

Public Sub AddLine (Text As String, LineWidth As Double)
	Lines.Add(Text)
	Widths.Add(LineWidth)
	If LineWidth > Width Then Width = LineWidth
End Sub

Public Sub LineCount As Int
	Return Lines.Size
End Sub
