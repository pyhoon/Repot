B4J=true
Group=Layout
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'B4J text measurement adapter.
'
'Fonts are measured with java.awt.Font and java.awt.font.TextLayout using
'an explicit FontRenderContext built from public RenderingHints constants.
'No Graphics2D and no UI thread are involved, so the adapter works with
'java.awt.headless=true and in a server build.
'
'AWT font sizes are integers. To support fractional point sizes, every
'font is created at BaseSize (1000) and measured advances and vertical
'metrics are scaled linearly by Size / BaseSize. Glyph advances scale
'linearly with font size under fractional metrics, so this is exact to
'double precision and avoids rounding the template's size.
'
'The adapter never guesses widths. If AWT cannot be initialised, or a
'specific string cannot be laid out, an error diagnostic is recorded and
'zero is returned; layout must treat that as a hard failure.

Sub Class_Globals
	Public Diagnostics As RepotDiagnostics
	Public IsAvailable As Boolean
	Public LastError As String
	Public MaxLines As Int

	Private mBaseSize As Int
	Private mFrc As JavaObject
	Private mHintSource As JavaObject
	Private mFonts As Map
	Private mBaseFonts As Map
	Private mWidths As Map
	Private mWarned As Map
	Private mTooLong As Boolean
End Sub

Public Sub Initialize (Diags As RepotDiagnostics)
	Diagnostics = Diags
	If Diagnostics = Null Then
		Dim fresh As RepotDiagnostics
		fresh.Initialize
		Diagnostics = fresh
	End If
	IsAvailable = False
	LastError = ""
	MaxLines = 10000
	mBaseSize = 1000
	mFonts.Initialize
	mBaseFonts.Initialize
	mWidths.Initialize
	mWarned.Initialize
	mTooLong = False

	Try
		Dim empty As JavaObject
		empty.InitializeNewInstance("java.util.HashMap", Null)
		mHintSource.InitializeNewInstance("java.awt.RenderingHints", Array(empty))
		Dim aaOn As Object = mHintSource.GetField("VALUE_TEXT_ANTIALIAS_ON")
		Dim fmOn As Object = mHintSource.GetField("VALUE_FRACTIONALMETRICS_ON")
		mFrc.InitializeNewInstance("java.awt.font.FontRenderContext", Array(Null, aaOn, fmOn))
		IsAvailable = True
	Catch
		LastError = LastException.Message
		Diagnostics.AddError("E-MEA-001", "text measurement is unavailable: " & LastError, "")
	End Try
End Sub

'Resolves one requested family. Falls back to the platform default when
'the family is unavailable, recording a warning.
Public Sub ResolveFont (Family As String, Bold As Boolean, Italic As Boolean, SizePt As Double) As RepotFont
	Dim families As List
	families.Initialize
	Dim name As String = Family.Trim
	If name.Length > 0 Then families.Add(name)
	Return ResolveList(families, Bold, Italic, SizePt)
End Sub

'Resolves a style's declared fallback list, outermost first. A warning is
'recorded whenever the first declared family is not the one used.
Public Sub ResolveStyle (Style As RepotTextStyle) As RepotFont
	Return ResolveList(Style.Family, Style.Bold, Style.Italic, Style.Size)
End Sub

'Nominal line height in points: the style's font size times its line
'spacing. Platform leading is deliberately not part of this number.
Public Sub LineHeight (Style As RepotTextStyle) As Double
	Dim spacing As Double = Style.LineSpacing
	If spacing <= 0 Then spacing = 1.2
	Return Style.Size * spacing
End Sub

'Width of a single line in points. The text is not wrapped and line
'breaks inside Text are not meaningful; use MeasureBlock for blocks.
Public Sub MeasureLine (Text As String, Style As RepotTextStyle) As Double
	Dim f As RepotFont = ResolveStyle(Style)
	Return MeasureWithFont(Text.Trim, f)
End Sub

'Wraps Text to MaxWidth and returns final lines and metrics. Wrapping is
'at spaces and tabs; runs of whitespace between words collapse to one
'space. A word wider than MaxWidth is broken by character. Explicit line
'breaks are honoured. Trailing whitespace is removed before measuring.
Public Sub MeasureBlock (Text As String, Style As RepotTextStyle, MaxWidth As Double) As RepotTextMetrics
	Dim m As RepotTextMetrics
	m.Initialize
	mTooLong = False

	Dim f As RepotFont = ResolveStyle(Style)
	m.Font = f
	m.Ascent = f.Ascent
	m.Descent = f.Descent
	m.LineHeight = LineHeight(Style)

	Dim normal As String = Text.Replace(Chr(13) & Chr(10), Chr(10)).Replace(Chr(13), Chr(10))
	Dim start As Int = 0
	Dim i As Int = 0
	Do While i <= normal.Length
		If i = normal.Length Or normal.SubString2(i, i + 1) = Chr(10) Then
			WrapParagraph(normal.SubString2(start, i), f, MaxWidth, m)
			start = i + 1
		End If
		i = i + 1
	Loop

	m.Height = m.LineCount * m.LineHeight
	Return m
End Sub

'--------------------------------------------------------------- fonts

Private Sub ResolveList (Families As List, Bold As Boolean, Italic As Boolean, SizePt As Double) As RepotFont
	Dim key As String = StyleKey(Families, Bold, Italic, SizePt)
	If mFonts.ContainsKey(key) Then Return mFonts.Get(key)

	Dim rf As RepotFont
	rf.Initialize
	rf.Bold = Bold
	rf.Italic = Italic
	rf.Size = SizePt
	rf.RequestedFamily = PrimaryFamily(Families)
	rf.Key = FontKey(rf.RequestedFamily, Bold, Italic, SizePt)

	If IsAvailable = False Then
		rf.Family = rf.RequestedFamily
		mFonts.Put(key, rf)
		Return rf
	End If

	Dim chosen As String = ""
	Dim i As Int
	For i = 0 To Families.Size - 1
		Dim candidate As String = Families.Get(i)
		If IsFamilyAvailable(candidate, Bold, Italic) Then
			chosen = candidate
			Exit
		End If
	Next

	Dim substituted As Boolean = False
	If chosen.Length = 0 Then
		chosen = "Dialog"
		substituted = (rf.RequestedFamily.Length > 0)
	Else If rf.RequestedFamily.Length > 0 Then
		substituted = (chosen.ToLowerCase <> rf.RequestedFamily.ToLowerCase)
	End If

	rf.Substituted = substituted
	rf.Handle = BaseFont(chosen, Bold, Italic)
	rf.Family = BaseFamily(rf.Handle, chosen)
	rf.Key = FontKey(rf.Family, Bold, Italic, SizePt)
	If substituted Then WarnSubstitution(rf.RequestedFamily, rf.Family)
	ReadMetrics(rf)
	mFonts.Put(key, rf)
	Return rf
End Sub

Private Sub PrimaryFamily (Families As List) As String
	If Families.Size = 0 Then Return ""
	Dim f As String = Families.Get(0)
	Return f.Trim
End Sub

Private Sub StyleKey (Families As List, Bold As Boolean, Italic As Boolean, SizePt As Double) As String
	Dim sb As StringBuilder
	sb.Initialize
	For Each f As String In Families
		If sb.Length > 0 Then sb.Append("|")
		sb.Append(f.Trim)
	Next
	Return sb.ToString & "#" & FlagKey(Bold, Italic) & "#" & RepotUnits.FormatNumber(SizePt, 6)
End Sub

'Measurement identity: resolved family, face flags and size. Two templates
'that request different fallback lists but resolve to the same family
'share widths.
Private Sub FontKey (Family As String, Bold As Boolean, Italic As Boolean, SizePt As Double) As String
	Return Family.ToLowerCase & "#" & FlagKey(Bold, Italic) & "#" & RepotUnits.FormatNumber(SizePt, 6)
End Sub

Private Sub FlagKey (Bold As Boolean, Italic As Boolean) As String
	Dim flags As String = "n"
	If Bold Then flags = flags & "b"
	If Italic Then flags = flags & "i"
	Return flags
End Sub

Private Sub IsFamilyAvailable (Family As String, Bold As Boolean, Italic As Boolean) As Boolean
	Dim name As String = Family.Trim
	If name.Length = 0 Then Return False
	If IsLogicalFamily(name) Then Return True
	Dim handle As JavaObject = BaseFont(name, Bold, Italic)
	Dim actual As String = BaseFamily(handle, name)
	Return actual.ToLowerCase = name.ToLowerCase
End Sub

Private Sub IsLogicalFamily (Name As String) As Boolean
	Select Case Name.ToLowerCase
		Case "dialog", "dialoginput", "sansserif", "serif", "monospaced", "sans-serif", "monospace"
			Return True
	End Select
	Return False
End Sub

Private Sub BaseFont (Family As String, Bold As Boolean, Italic As Boolean) As JavaObject
	Dim key As String = Family.ToLowerCase & "#" & Bold & "#" & Italic
	If mBaseFonts.ContainsKey(key) Then Return mBaseFonts.Get(key)

	Dim style As Int = 0
	If Bold Then style = style + 1
	If Italic Then style = style + 2
	Dim f As JavaObject
	f.InitializeNewInstance("java.awt.Font", Array(Family, style, mBaseSize))
	mBaseFonts.Put(key, f)
	Return f
End Sub

Private Sub BaseFamily (Handle As JavaObject, Fallback As String) As String
	Try
		Dim fam As String = Handle.RunMethod("getFamily", Null)
		If fam.Length = 0 Then Return Fallback
		Return fam
	Catch
		Return Fallback
	End Try
End Sub

Private Sub ReadMetrics (F As RepotFont)
	Try
		Dim base As JavaObject = F.Handle
		Dim tl As JavaObject
		tl.InitializeNewInstance("java.awt.font.TextLayout", Array("Mg", base, mFrc))
		Dim scale As Double = F.Size / mBaseSize
		Dim a As Double = tl.RunMethod("getAscent", Null)
		Dim d As Double = tl.RunMethod("getDescent", Null)
		Dim g As Double = tl.RunMethod("getLeading", Null)
		F.Ascent = a * scale
		F.Descent = d * scale
		F.LineGap = g * scale
	Catch
		F.Ascent = 0
		F.Descent = 0
		F.LineGap = 0
		Diagnostics.AddError("E-MEA-002", "cannot read metrics for font '" & F.Family & "': " & LastException.Message, "")
	End Try
End Sub

Private Sub WarnSubstitution (Requested As String, Chosen As String)
	Dim key As String = "sub#" & Requested.ToLowerCase & "#" & Chosen.ToLowerCase
	If mWarned.ContainsKey(key) Then Return
	mWarned.Put(key, True)
	Diagnostics.AddWarning("W-MEA-001", "font family '" & Requested & "' is not available; using '" & Chosen & "'", "")
End Sub

'--------------------------------------------------------------- text

Private Sub MeasureWithFont (Text As String, F As RepotFont) As Double
	If Text.Length = 0 Then Return 0
	If IsAvailable = False Then Return 0
	If F.Handle = Null Then Return 0

	Dim key As String = F.Key & Chr(1) & Text
	If mWidths.ContainsKey(key) Then Return mWidths.Get(key)

	Try
		Dim base As JavaObject = F.Handle
		Dim tl As JavaObject
		tl.InitializeNewInstance("java.awt.font.TextLayout", Array(Text, base, mFrc))
		Dim raw As Double = tl.RunMethod("getAdvance", Null)
		Dim w As Double = raw * F.Size / mBaseSize
		mWidths.Put(key, w)
		Return w
	Catch
		Dim shortText As String = Text
		If shortText.Length > 40 Then shortText = shortText.SubString2(0, 40) & "..."
		Dim key2 As String = "measure#" & shortText
		If mWarned.ContainsKey(key2) = False Then
			mWarned.Put(key2, True)
			Diagnostics.AddError("E-MEA-003", "cannot measure text '" & shortText & "': " & LastException.Message, "")
		End If
		Return 0
	End Try
End Sub

Private Sub WrapParagraph (Para As String, F As RepotFont, MaxWidth As Double, M As RepotTextMetrics)
	Dim words As List = SplitWords(Para)
	If words.Size = 0 Then
		AddMeasuredLine(M, "", F)
		Return
	End If

	Dim current As String = ""
	For Each word As String In words
		If MaxWidth <= 0 Then
			If current.Length = 0 Then
				current = word
			Else
				current = current & " " & word
			End If
		Else If current.Length = 0 Then
			Dim wid As Double = MeasureWithFont(word, F)
			If wid <= MaxWidth Then
				current = word
			Else
				current = PlaceLongWord(word, F, MaxWidth, M)
			End If
		Else
			Dim candidate As String = current & " " & word
			If MeasureWithFont(candidate, F) <= MaxWidth Then
				current = candidate
			Else
				AddMeasuredLine(M, current, F)
				Dim wid2 As Double = MeasureWithFont(word, F)
				If wid2 <= MaxWidth Then
					current = word
				Else
					current = PlaceLongWord(word, F, MaxWidth, M)
				End If
			End If
		End If
	Next

	If current.Length > 0 Then AddMeasuredLine(M, current, F)
End Sub

'Adds every full chunk of an over-wide word to M and returns the final
'chunk, which the caller keeps as the current line.
Private Sub PlaceLongWord (Word As String, F As RepotFont, MaxWidth As Double, M As RepotTextMetrics) As String
	Dim chunk As String = ""
	Dim i As Int = 0
	Do While i < Word.Length
		Dim c As String = Word.SubString2(i, i + 1)
		Dim trial As String = chunk & c
		If chunk.Length > 0 And MeasureWithFont(trial, F) > MaxWidth Then
			AddMeasuredLine(M, chunk, F)
			chunk = c
		Else
			chunk = trial
		End If
		i = i + 1
	Loop
	Return chunk
End Sub

Private Sub AddMeasuredLine (M As RepotTextMetrics, Line As String, F As RepotFont)
	If M.LineCount >= MaxLines Then
		If mTooLong = False Then
			mTooLong = True
			Diagnostics.AddError("E-MEA-004", "text block exceeds " & MaxLines & " lines", "")
		End If
		Return
	End If
	Dim t As String = Line.Trim
	M.AddLine(t, MeasureWithFont(t, F))
End Sub

Private Sub SplitWords (Para As String) As List
	Dim words As List
	words.Initialize
	Dim cur As StringBuilder
	cur.Initialize
	Dim i As Int = 0
	Do While i < Para.Length
		Dim c As String = Para.SubString2(i, i + 1)
		Dim code As Int = Asc(c)
		If code = 32 Or code = 9 Then
			If cur.Length > 0 Then
				words.Add(cur.ToString)
				cur.Initialize
			End If
		Else
			cur.Append(c)
		End If
		i = i + 1
	Loop
	If cur.Length > 0 Then words.Add(cur.ToString)
	Return words
End Sub
