B4J=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
'Shared spreadsheet cell typing and display formatting for the XLSX and
'ODS exporters. Pure B4X: no platform API and no format-library code.
'
'Cell type follows the bound value: number, boolean, date (declared
'date/datetime fields, including ISO strings) or text. Dates are
'converted through calendar components, never through the ambient
'timezone. The Excel serial epoch is 1899-12-30; the 1900 leap-year bug
'is documented, not emulated, so dates before 1900-03-01 differ by one
'from Excel's own numbering.

Sub Process_Globals
End Sub

'Returns "empty", "number", "boolean", "date" or "text".
Public Sub CellKind (Value As Object, Fld As ReportFieldDef) As String
	If Value = Null Then Return "empty"

	Dim declared As String = ""
	If Fld <> Null Then declared = Fld.DataType

	If Value Is Boolean Then Return "boolean"

	If IsNumber(Value) Then
		If declared = "date" Or declared = "datetime" Then Return "date"
		Return "number"
	End If

	If declared = "date" Or declared = "datetime" Then
		If DateParts(Value).Size > 0 Then Return "date"
	End If

	Return "text"
End Sub

'Returns [year, month, day, hour, minute, second] for a date value
'(numeric B4X ticks or one of the documented ISO strings), or an empty
'list when the value is not a date. Callers test `Size`, never Null:
'B4X turns a Null return into an uninitialized List.
Public Sub DateParts (Value As Object) As List
	If Value = Null Then Return EmptyParts()

	If Value Is String Then Return ParseIso(Value)

	If IsNumber(Value) Then
		Dim ticks As Long = Value
		Dim l As List
		l.Initialize
		l.Add(DateTime.GetYear(ticks))
		l.Add(DateTime.GetMonth(ticks))
		l.Add(DateTime.GetDayOfMonth(ticks))
		l.Add(DateTime.GetHour(ticks))
		l.Add(DateTime.GetMinute(ticks))
		l.Add(DateTime.GetSecond(ticks))
		Return l
	End If

	Return EmptyParts()
End Sub

'Excel date serial (1899-12-30 epoch), timezone-free. Returns 0 for a
'value that is not a date.
Public Sub ExcelSerial (Value As Object) As Double
	Dim p As List = DateParts(Value)
	If p.Size < 6 Then Return 0

	Dim y As Int = p.Get(0)
	Dim mo As Int = p.Get(1)
	Dim da As Int = p.Get(2)
	Dim h As Int = p.Get(3)
	Dim mi As Int = p.Get(4)
	Dim se As Int = p.Get(5)

	Dim days As Long = DaysFromCivil(y, mo, da) - DaysFromCivil(1899, 12, 30)
	Dim secs As Long = h * 3600 + mi * 60 + se
	Return days + secs / 86400
End Sub

'ODF office:date-value, ISO 8601. Midnight dates have no time part.
Public Sub OdfDateValue (Value As Object) As String
	Dim p As List = DateParts(Value)
	If p.Size < 6 Then Return ""

	Dim y As Int = p.Get(0)
	Dim mo As Int = p.Get(1)
	Dim da As Int = p.Get(2)
	Dim h As Int = p.Get(3)
	Dim mi As Int = p.Get(4)
	Dim se As Int = p.Get(5)

	Dim out As String = Pad4(y) & "-" & Pad2(mo) & "-" & Pad2(da)
	If h + mi + se > 0 Then
		out = out & "T" & Pad2(h) & ":" & Pad2(mi) & ":" & Pad2(se)
	End If
	Return out
End Sub

'Number format parts for the ODF styles: decimals, grouping, prefix and
'suffix. Defaults follow the declared type.
Public Sub NumberParts (Fmt As Map, DeclaredType As String) As Map
	Dim out As Map
	out.Initialize

	Dim dec As Int = 0
	If DeclaredType = "decimal" Then dec = 2
	If Fmt.ContainsKey("decimals") Then dec = Fmt.Get("decimals")
	If dec < 0 Then dec = 0
	If dec > 6 Then dec = 6
	out.Put("decimals", dec)

	Dim grouping As Boolean = False
	If Fmt.ContainsKey("grouping") Then grouping = Fmt.Get("grouping")
	out.Put("grouping", grouping)

	Dim prefix As String = ""
	If Fmt.ContainsKey("prefix") Then prefix = Fmt.Get("prefix")
	out.Put("prefix", prefix)

	Dim suffix As String = ""
	If Fmt.ContainsKey("suffix") Then suffix = Fmt.Get("suffix")
	out.Put("suffix", suffix)

	Return out
End Sub

'Excel number format code (numFmt formatCode). "General" means no format.
Public Sub ExcelFormatCode (Fmt As Map, DeclaredType As String) As String
	Dim typ As String = ""
	If Fmt.ContainsKey("type") Then typ = Fmt.Get("type")

	If typ = "text" Or typ = "boolean" Then Return "General"
	If typ = "date" Then Return ExcelDateCode(DatePattern(Fmt, DeclaredType))
	If typ = "number" Then Return ExcelNumberCode(Fmt, DeclaredType)

	'No explicit type: defaults by the declared field type.
	If DeclaredType = "date" Or DeclaredType = "datetime" Then
		Return ExcelDateCode(DatePattern(Fmt, DeclaredType))
	End If
	If DeclaredType = "integer" Or DeclaredType = "decimal" Then
		Return ExcelNumberCode(Fmt, DeclaredType)
	End If

	Return "General"
End Sub

'Display text for a value: the cached text:p in ODS and the measurement
'input for column widths in both writers.
Public Sub DisplayText (Value As Object, Fmt As Map, DeclaredType As String) As String
	If Value = Null Then Return ""

	If Value Is Boolean Then
		Dim b As Boolean = Value
		If b Then Return "TRUE"
		Return "FALSE"
	End If

	If DeclaredType = "date" Or DeclaredType = "datetime" Then
		Dim parts As List = DateParts(Value)
		If parts.Size > 0 Then Return DateText(parts, DatePattern(Fmt, DeclaredType))
	End If

	If IsNumber(Value) Then
		Dim p As Map = NumberParts(Fmt, DeclaredType)
		Dim d As Double = Value
		Dim dec As Int = p.Get("decimals")
		Dim s As String = ReportUnits.FormatNumber(d, dec)
		Dim grouping As Boolean = p.Get("grouping")
		If grouping Then s = ReportUnits.AddGrouping(s)
		'The sign goes before the prefix, as Excel renders "-$1,200.00".
		Dim negative As Boolean = s.StartsWith("-")
		If negative Then s = s.SubString(1)
		Dim out As String = p.Get("prefix") & s & p.Get("suffix")
		If negative Then out = "-" & out
		Return out
	End If

	Return Value
End Sub

'ODF automatic-style fragment for a number cell style.
Public Sub OdfNumberStyle (Name As String, Fmt As Map, DeclaredType As String) As String
	Dim p As Map = NumberParts(Fmt, DeclaredType)
	Dim dec As Int = p.Get("decimals")
	Dim grouping As Boolean = p.Get("grouping")
	Dim prefix As String = p.Get("prefix")
	Dim suffix As String = p.Get("suffix")

	Dim out As StringBuilder
	out.Initialize
	out.Append("<number:number-style style:name=""").Append(Name).Append(""">")
	If prefix.Length > 0 Then out.Append("<number:text>").Append(XmlEscape(prefix)).Append("</number:text>")
	out.Append("<number:number number:decimal-places=""").Append(dec).Append(""" number:min-decimal-places=""").Append(dec).Append("""")
	If grouping Then out.Append(" number:grouping=""true""")
	out.Append("/>")
	If suffix.Length > 0 Then out.Append("<number:text>").Append(XmlEscape(suffix)).Append("</number:text>")
	out.Append("</number:number-style>")
	Return out.ToString
End Sub

'ODF automatic-style fragment for a date/datetime cell style.
Public Sub OdfDateStyle (Name As String, Pattern As String) As String
	Dim out As StringBuilder
	out.Initialize
	out.Append("<number:date-style style:name=""").Append(Name).Append(""">")
	out.Append(OdfDateTokens(Pattern))
	out.Append("</number:date-style>")
	Return out.ToString
End Sub

Public Sub XmlEscape (s As String) As String
	Dim out As String = s
	out = out.Replace("&", "&amp;")
	out = out.Replace("<", "&lt;")
	out = out.Replace(">", "&gt;")
	Return out
End Sub

Private Sub ExcelNumberCode (Fmt As Map, DeclaredType As String) As String
	Dim p As Map = NumberParts(Fmt, DeclaredType)
	Dim code As String = QuoteCode(p.Get("prefix")) & NumberCore(p) & QuoteCode(p.Get("suffix"))
	Return code
End Sub

Private Sub NumberCore (P As Map) As String
	Dim dec As Int = P.Get("decimals")
	Dim grouping As Boolean = P.Get("grouping")

	Dim s As String
	If grouping Then
		s = "#,##0"
	Else
		s = "0"
	End If
	If dec > 0 Then
		Dim frac As String = ""
		Dim k As Int
		For k = 1 To dec
			frac = frac & "0"
		Next
		s = s & "." & frac
	End If
	Return s
End Sub

Private Sub ExcelDateCode (Pattern As String) As String
	'Our pattern tokens are Java-like: MM is month, mm is minute and
	'HH is a 24-hour clock. Excel resolves mm as minutes only when it
	'follows h or precedes s, which is exactly how a translated
	'"yyyy-mm-dd hh:mm:ss" reads.
	Dim out As String = Pattern
	out = out.Replace("MM", "mm")
	out = out.Replace("HH", "hh")
	Return out
End Sub

Private Sub DatePattern (Fmt As Map, DeclaredType As String) As String
	If Fmt.ContainsKey("pattern") Then
		Dim p As String = Fmt.Get("pattern")
		If p.Length > 0 Then Return p
	End If
	If DeclaredType = "datetime" Then Return "yyyy-MM-dd HH:mm:ss"
	Return "yyyy-MM-dd"
End Sub

Private Sub DateText (Parts As List, Pattern As String) As String
	Dim y As Int = Parts.Get(0)
	Dim mo As Int = Parts.Get(1)
	Dim da As Int = Parts.Get(2)
	Dim h As Int = Parts.Get(3)
	Dim mi As Int = Parts.Get(4)
	Dim se As Int = Parts.Get(5)

	Dim out As String = Pattern
	out = out.Replace("yyyy", Pad4(y))
	out = out.Replace("MM", Pad2(mo))
	out = out.Replace("dd", Pad2(da))
	out = out.Replace("HH", Pad2(h))
	out = out.Replace("mm", Pad2(mi))
	out = out.Replace("ss", Pad2(se))
	Return out
End Sub

Private Sub OdfDateTokens (Pattern As String) As String
	Dim out As StringBuilder
	out.Initialize
	Dim lit As StringBuilder
	lit.Initialize

	Dim i As Int = 0
	Do While i < Pattern.Length
		Dim tok As String = ""
		Dim adv As Int = 1

		If i + 4 <= Pattern.Length Then
			If Pattern.SubString2(i, i + 4) = "yyyy" Then
				tok = "<number:year number:style=""long""/>"
				adv = 4
			End If
		End If

		If tok.Length = 0 And i + 2 <= Pattern.Length Then
			Dim two As String = Pattern.SubString2(i, i + 2)
			If two = "MM" Then
				tok = "<number:month number:style=""long""/>"
			Else If two = "dd" Then
				tok = "<number:day number:style=""long""/>"
			Else If two = "HH" Then
				tok = "<number:hours number:style=""long""/>"
			Else If two = "mm" Then
				tok = "<number:minutes number:style=""long""/>"
			Else If two = "ss" Then
				tok = "<number:seconds number:style=""long""/>"
			End If
			If tok.Length > 0 Then adv = 2
		End If

		If tok.Length > 0 Then
			If lit.Length > 0 Then
				out.Append("<number:text>").Append(XmlEscape(lit.ToString)).Append("</number:text>")
				lit.Initialize
			End If
			out.Append(tok)
			i = i + adv
		Else
			lit.Append(Pattern.SubString2(i, i + 1))
			i = i + 1
		End If
	Loop

	If lit.Length > 0 Then
		out.Append("<number:text>").Append(XmlEscape(lit.ToString)).Append("</number:text>")
	End If
	Return out.ToString
End Sub

'Parses yyyy-MM-dd, yyyy-MM-dd HH:mm, yyyy-MM-dd HH:mm:ss and the
'"T" variants. Anything else stays text.
Private Sub EmptyParts As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Private Sub ParseIso (Raw As String) As List
	Dim s As String = Raw.Trim
	If s.Length <> 10 And s.Length <> 16 And s.Length <> 19 Then Return EmptyParts()
	If s.SubString2(4, 5) <> "-" Or s.SubString2(7, 8) <> "-" Then Return EmptyParts()

	Dim ys As String = s.SubString2(0, 4)
	Dim ms As String = s.SubString2(5, 7)
	Dim ds As String = s.SubString2(8, 10)
	If AllDigits(ys) = False Or AllDigits(ms) = False Or AllDigits(ds) = False Then Return EmptyParts()

	Dim y As Int = Bit.ParseInt(ys, 10)
	Dim mo As Int = Bit.ParseInt(ms, 10)
	Dim da As Int = Bit.ParseInt(ds, 10)
	Dim h As Int = 0
	Dim mi As Int = 0
	Dim se As Int = 0

	If s.Length > 10 Then
		Dim sep As String = s.SubString2(10, 11)
		If sep <> " " And sep <> "T" Then Return EmptyParts()
		If s.SubString2(13, 14) <> ":" Then Return EmptyParts()

		Dim hs As String = s.SubString2(11, 13)
		Dim mis As String = s.SubString2(14, 16)
		If AllDigits(hs) = False Or AllDigits(mis) = False Then Return EmptyParts()
		h = Bit.ParseInt(hs, 10)
		mi = Bit.ParseInt(mis, 10)

		If s.Length = 19 Then
			If s.SubString2(16, 17) <> ":" Then Return EmptyParts()
			Dim ss As String = s.SubString2(17, 19)
			If AllDigits(ss) = False Then Return EmptyParts()
			se = Bit.ParseInt(ss, 10)
		End If
	End If

	If y < 1 Or y > 9999 Then Return EmptyParts()
	If mo < 1 Or mo > 12 Then Return EmptyParts()
	If da < 1 Or da > DaysInMonth(y, mo) Then Return EmptyParts()
	If h > 23 Or mi > 59 Or se > 59 Then Return EmptyParts()

	Dim l As List
	l.Initialize
	l.Add(y)
	l.Add(mo)
	l.Add(da)
	l.Add(h)
	l.Add(mi)
	l.Add(se)
	Return l
End Sub

Private Sub AllDigits (s As String) As Boolean
	Dim i As Int
	For i = 0 To s.Length - 1
		Dim code As Int = Asc(s.SubString2(i, i + 1))
		If code < 48 Or code > 57 Then Return False
	Next
	Return True
End Sub

Private Sub DaysInMonth (y As Int, m As Int) As Int
	If m = 2 Then
		If IsLeap(y) Then Return 29
		Return 28
	End If
	If m = 4 Or m = 6 Or m = 9 Or m = 11 Then Return 30
	Return 31
End Sub

Private Sub IsLeap (y As Int) As Boolean
	If y Mod 400 = 0 Then Return True
	If y Mod 100 = 0 Then Return False
	Return (y Mod 4 = 0)
End Sub

'Days since 1970-01-01 for a proleptic Gregorian date, by calendar
'components only (Howard Hinnant's civil-days algorithm).
Private Sub DaysFromCivil (y As Int, m As Int, d As Int) As Long
	Dim yy As Long = y
	Dim mm As Long = m
	If mm <= 2 Then yy = yy - 1
	Dim era As Long = Floor(yy / 400)
	Dim yoe As Long = yy - era * 400
	Dim mp As Long = (mm + 9) Mod 12
	Dim doy As Long = Floor((153 * mp + 2) / 5) + d - 1
	Dim doe As Long = yoe * 365 + Floor(yoe / 4) - Floor(yoe / 100) + doy
	Return era * 146097 + doe - 719468
End Sub

Private Sub QuoteCode (s As String) As String
	If s.Length = 0 Then Return ""
	Dim t As String = s.Replace("""", """""")
	Return """" & t & """"
End Sub

Private Sub Pad2 (n As Int) As String
	Dim s As String = n
	If s.Length < 2 Then s = "0" & s
	Return s
End Sub

Private Sub Pad4 (n As Int) As String
	Dim s As String = n
	Do While s.Length < 4
		s = "0" & s
	Loop
	Return s
End Sub
