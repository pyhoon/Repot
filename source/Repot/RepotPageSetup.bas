B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Page setup. All lengths are points after loading.
Sub Class_Globals
	Public SizeName As String
Public Width As Double
Public Height As Double
Public Orientation As String
Public MarginTop As Double
Public MarginRight As Double
Public MarginBottom As Double
Public MarginLeft As Double
Public GridColumns As Int
Public GridRows As Int
Public CellWidth As Double
Public CellHeight As Double
Public FooterReserve As Double
Public Dpi As Double
End Sub

Public Sub Initialize
	SizeName = "A4"
	Width = 595.2755905511812
	Height = 841.8897637795277
	Orientation = "portrait"
	MarginTop = 36
	MarginRight = 36
	MarginBottom = 36
	MarginLeft = 36
	GridColumns = 0
	GridRows = 0
	CellWidth = 0
	CellHeight = 0
	FooterReserve = 0
	Dpi = 0
End Sub

Public Sub ContentWidth As Double
	Return Width - MarginLeft - MarginRight
End Sub

Public Sub ContentHeight As Double
	Return Height - MarginTop - MarginBottom
End Sub

Public Sub IsLandscape As Boolean
	Return Orientation = "landscape"
End Sub
