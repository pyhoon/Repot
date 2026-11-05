B4J=true
Group=Core
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
'Repot unit conversion and deterministic number formatting.
'
'Internal geometry is always points. Templates may express lengths with a
'suffix (pt, mm, cm, in) and the loader converts once. Pixels require an
'explicit DPI; there is no ambient screen assumption.

Sub Process_Globals
	Public LastUnitError As String
End Sub

Public Sub ResetUnitError
	LastUnitError = ""
End Sub

Public Sub Points (Value As Double) As Double
	Return Value
End Sub

Public Sub Millimetres (Value As Double) As Double
	Return Value * 72.0 / 25.4
End Sub

Public Sub Centimetres (Value As Double) As Double
	Return Value * 72.0 / 2.54
End Sub

Public Sub Inches (Value As Double) As Double
	Return Value * 72.0
End Sub

Public Sub Pixels (Value As Double, Dpi As Double) As Double
	If Dpi <= 0 Then
		LastUnitError = "pixel lengths require an explicit page.dpi"
		Return 0
	End If
	Return Value * 72.0 / Dpi
End Sub

'Parses a number or a suffixed length string into points.
'Returns 0 and sets LastUnitError when invalid.
Public Sub ParseLength (Value As Object, Dpi As Double) As Double
	LastUnitError = ""
	If Value = Null Then
		LastUnitError = "length is null"
		Return 0
	End If
	If IsNumber(Value) Then
		Dim d As Double = Value
		Return d
	End If
	If (Value Is String) = False Then
		LastUnitError = "length must be a number or a string with a unit"
		Return 0
	End If
	Dim s As String = Value
	s = s.Trim.ToLowerCase
	If s.Length = 0 Then
		LastUnitError = "length is empty"
		Return 0
	End If

	Dim i As Int = 0
	Dim seenDot As Boolean = False
	Dim seenDigit As Boolean = False
	Do While i < s.Length
		Dim c As String = s.SubString2(i, i + 1)
		Dim code As Int = Asc(c)
		If code >= 48 And code <= 57 Then
			seenDigit = True
		Else If c = "." Then
			If seenDot Then
				LastUnitError = "length has more than one decimal point"
				Return 0
			End If
			seenDot = True
		Else If (c = "-" Or c = "+") And i = 0 Then
			' sign
		Else
			Exit
		End If
		i = i + 1
	Loop

	If seenDigit = False Or i = 0 Then
		LastUnitError = "length has no numeric part"
		Return 0
	End If

	Dim numberPart As String = s.SubString2(0, i)
	Dim unitPart As String = s.SubString(i).Trim
	Dim number As Double = ParseNumberText(numberPart)
	If LastUnitError.Length > 0 Then Return 0

	Select Case unitPart
		Case "", "pt"
			Return number
		Case "mm"
			Return Millimetres(number)
		Case "cm"
			Return Centimetres(number)
		Case "in"
			Return Inches(number)
		Case "px"
			Return Pixels(number, Dpi)
		Case Else
			LastUnitError = "unknown unit '" & unitPart & "'"
			Return 0
	End Select
End Sub

'Parses a plain decimal string. No exponent, no grouping, invariant dot.
Public Sub ParseNumberText (s As String) As Double
	LastUnitError = ""
	If s.Length = 0 Then
		LastUnitError = "number is empty"
		Return 0
	End If

	Dim sign As Double = 1
	Dim i As Int = 0
	Dim c As String = s.SubString2(0, 1)
	If c = "-" Then
		sign = -1
		i = 1
	Else If c = "+" Then
		i = 1
	End If

	Dim intPart As Double = 0
	Dim fracPart As Double = 0
	Dim fracScale As Double = 1
	Dim digits As Int = 0
	Dim inFraction As Boolean = False

	Do While i < s.Length
		c = s.SubString2(i, i + 1)
		Dim code As Int = Asc(c)
		If c = "." Then
			If inFraction Then
				LastUnitError = "number has more than one decimal point"
				Return 0
			End If
			inFraction = True
		Else If code >= 48 And code <= 57 Then
			Dim digit As Int = code - 48
			If inFraction Then
				fracScale = fracScale * 10
				fracPart = fracPart + digit / fracScale
			Else
				intPart = intPart * 10 + digit
			End If
			digits = digits + 1
		Else
			LastUnitError = "invalid character '" & c & "' in number"
			Return 0
		End If
		i = i + 1
	Loop

	If digits = 0 Then
		LastUnitError = "number has no digits"
		Return 0
	End If
	Return sign * (intPart + fracPart)
End Sub

'Rounds half-up to a fixed number of decimals. Negative values round away
'from zero at the half, matching the geometry rule in docs/architecture.md.
Public Sub RoundTo (Value As Double, Decimals As Int) As Double
	If Decimals < 0 Then Decimals = 0
	If Decimals > 6 Then Decimals = 6
	Dim scale As Double = 1
	Dim k As Int
	For k = 1 To Decimals
		scale = scale * 10
	Next
	Dim scaled As Long = Round(Abs(Value) * scale)
	Dim result As Double = scaled / scale
	If Value < 0 Then result = -result
	Return result
End Sub

'Formats with an invariant dot and exactly Decimals fraction digits.
'Used by the canonical JSON writer so goldens never depend on a locale.
Public Sub FormatNumber (Value As Double, Decimals As Int) As String
	If Decimals < 0 Then Decimals = 0
	If Decimals > 6 Then Decimals = 6

	Dim negative As Boolean = Value < 0
	Dim a As Double = Abs(Value)
	Dim scale As Long = 1
	Dim k As Int
	For k = 1 To Decimals
		scale = scale * 10
	Next
	Dim scaled As Long = Round(a * scale)
	Dim whole As Long = Floor(scaled / scale)
	Dim frac As Long = scaled - whole * scale

	Dim s As String = whole
	If Decimals > 0 Then
		Dim fs As String = frac
		Do While fs.Length < Decimals
			fs = "0" & fs
		Loop
		s = s & "." & fs
	End If
	If negative And scaled <> 0 Then s = "-" & s
	Return s
End Sub

'Inserts thousands separators in the integer part of an invariant
'number string; the fraction part is returned unchanged. Shared by the
'layout's number format and the spreadsheet exporters' display text.
Public Sub AddGrouping (s As String) As String
	Dim dot As Int = s.IndexOf(".")
	Dim intPart As String
	Dim fracPart As String
	If dot >= 0 Then
		intPart = s.SubString2(0, dot)
		fracPart = s.SubString(dot)
	Else
		intPart = s
		fracPart = ""
	End If
	Dim negative As Boolean = intPart.StartsWith("-")
	If negative Then intPart = intPart.SubString(1)
	Dim out As StringBuilder
	out.Initialize
	Dim i As Int = intPart.Length - 1
	Dim count As Int = 0
	Do While i >= 0
		If count > 0 And count Mod 3 = 0 Then out.Insert(0, ",")
		out.Insert(0, intPart.SubString2(i, i + 1))
		count = count + 1
		i = i - 1
	Loop
	If negative Then out.Insert(0, "-")
	Return out.ToString & fracPart
End Sub

'Returns [width, height] in points for a named page size, or an empty list.
Public Sub PageSize (Name As String) As List
	Dim l As List
	l.Initialize
	Select Case Name.Trim.ToLowerCase
		Case "a4"
			l.Add(595.2755905511812)
			l.Add(841.8897637795277)
		Case "a5"
			l.Add(419.5275590551181)
			l.Add(595.2755905511812)
		Case "letter"
			l.Add(612.0)
			l.Add(792.0)
		Case "legal"
			l.Add(612.0)
			l.Add(1008.0)
	End Select
	Return l
End Sub

Public Sub IsKnownPageSize (Name As String) As Boolean
	Return PageSize(Name).Size > 0
End Sub
