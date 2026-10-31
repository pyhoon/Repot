B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Resolved font used by measurement and the render document.
'
'Key is the measurement identity. Family is the family the platform
'actually selected; RequestedFamily is what the template asked for.
'Substituted is true only when none of the declared families were
'available and the platform default was used. Ascent, Descent and LineGap
'are in points at Size.
'
'Handle is the platform font object. It is opaque and may be Null when
'measurement is unavailable.
Sub Class_Globals
	Public Key As String
	Public RequestedFamily As String
	Public Family As String
	Public Substituted As Boolean
	Public Bold As Boolean
	Public Italic As Boolean
	Public Size As Double
	Public Ascent As Double
	Public Descent As Double
	Public LineGap As Double
	Public Handle As Object
End Sub

Public Sub Initialize
	Key = ""
	RequestedFamily = ""
	Family = ""
	Substituted = False
	Bold = False
	Italic = False
	Size = 0
	Ascent = 0
	Descent = 0
	LineGap = 0
	Handle = Null
End Sub

'True when the platform reported usable vertical metrics.
Public Sub HasMetrics As Boolean
	Return Ascent > 0 Or Descent > 0
End Sub
