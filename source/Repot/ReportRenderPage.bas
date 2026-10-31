B4J=true
Group=Render
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'One page of the render document: an ordered list of drawing operations
'and named anchors. The page is fully resolved; there are no expressions,
'bindings or style references left.
'
'Add* methods round geometry to 0.01 pt before storing it. Page dimensions
'are kept at full precision because they are not drawing operations.
Sub Class_Globals
	Public Index As Int
	Public Width As Double
	Public Height As Double
	Public Ops As List
	Public Anchors As List
End Sub

Public Sub Initialize
	Index = 0
	Width = 0
	Height = 0
	Ops.Initialize
	Anchors.Initialize
End Sub

Public Sub AddText (X As Double, Y As Double, W As Double, H As Double, Baseline As Double, Text As String, FontName As String, FontSize As Double, Bold As Boolean, Italic As Boolean, Underline As Boolean, Colour As String, Align As String) As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "text"
	op.X = ReportUnits.RoundTo(X, 2)
	op.Y = ReportUnits.RoundTo(Y, 2)
	op.Width = ReportUnits.RoundTo(W, 2)
	op.Height = ReportUnits.RoundTo(H, 2)
	op.Baseline = ReportUnits.RoundTo(Baseline, 2)
	op.Text = Text
	op.FontName = FontName
	op.FontSize = FontSize
	op.Bold = Bold
	op.Italic = Italic
	op.Underline = Underline
	op.Colour = Colour
	If Align.Length = 0 Then
		op.Align = "left"
	Else
		op.Align = Align
	End If
	Ops.Add(op)
	Return op
End Sub

Public Sub AddImage (X As Double, Y As Double, W As Double, H As Double, ResourcePath As String, PixelWidth As Int, PixelHeight As Int, Dpi As Double, Fit As String, Handle As Object) As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "image"
	op.X = ReportUnits.RoundTo(X, 2)
	op.Y = ReportUnits.RoundTo(Y, 2)
	op.Width = ReportUnits.RoundTo(W, 2)
	op.Height = ReportUnits.RoundTo(H, 2)
	op.ResourcePath = ResourcePath
	op.PixelWidth = PixelWidth
	op.PixelHeight = PixelHeight
	op.Dpi = Dpi
	If Fit.Length = 0 Then
		op.Fit = "contain"
	Else
		op.Fit = Fit
	End If
	op.Handle = Handle
	Ops.Add(op)
	Return op
End Sub

Public Sub AddLine (X1 As Double, Y1 As Double, X2 As Double, Y2 As Double, LineWidth As Double, Colour As String, Dash As String) As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "line"
	op.X = ReportUnits.RoundTo(X1, 2)
	op.Y = ReportUnits.RoundTo(Y1, 2)
	op.X2 = ReportUnits.RoundTo(X2, 2)
	op.Y2 = ReportUnits.RoundTo(Y2, 2)
	op.LineWidth = LineWidth
	op.Colour = Colour
	op.Dash = Dash
	Ops.Add(op)
	Return op
End Sub

Public Sub AddRect (X As Double, Y As Double, W As Double, H As Double, LineWidth As Double, StrokeColour As String, FillColour As String, Radius As Double) As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "rect"
	op.X = ReportUnits.RoundTo(X, 2)
	op.Y = ReportUnits.RoundTo(Y, 2)
	op.Width = ReportUnits.RoundTo(W, 2)
	op.Height = ReportUnits.RoundTo(H, 2)
	op.LineWidth = LineWidth
	op.Colour = StrokeColour
	op.FillColour = FillColour
	op.Radius = ReportUnits.RoundTo(Radius, 2)
	Ops.Add(op)
	Return op
End Sub

Public Sub AddClip (X As Double, Y As Double, W As Double, H As Double) As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "clip"
	op.X = ReportUnits.RoundTo(X, 2)
	op.Y = ReportUnits.RoundTo(Y, 2)
	op.Width = ReportUnits.RoundTo(W, 2)
	op.Height = ReportUnits.RoundTo(H, 2)
	Ops.Add(op)
	Return op
End Sub

Public Sub AddRestore As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "restore"
	Ops.Add(op)
	Return op
End Sub

Public Sub AddLink (X As Double, Y As Double, W As Double, H As Double, Url As String, AnchorName As String) As ReportDrawOp
	Dim op As ReportDrawOp
	op.Initialize
	op.OpType = "link"
	op.X = ReportUnits.RoundTo(X, 2)
	op.Y = ReportUnits.RoundTo(Y, 2)
	op.Width = ReportUnits.RoundTo(W, 2)
	op.Height = ReportUnits.RoundTo(H, 2)
	op.Url = Url
	op.AnchorName = AnchorName
	Ops.Add(op)
	Return op
End Sub

Public Sub AddAnchor (AnchorName As String, X As Double, Y As Double) As ReportRenderAnchor
	Dim a As ReportRenderAnchor
	a.Initialize
	a.Name = AnchorName
	a.X = ReportUnits.RoundTo(X, 2)
	a.Y = ReportUnits.RoundTo(Y, 2)
	Anchors.Add(a)
	Return a
End Sub
