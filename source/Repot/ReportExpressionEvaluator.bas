B4J=true
Group=Expressions
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Recursive-descent expression evaluator. Parses and evaluates in one
'pass; no AST is retained. Supports the grammar documented in
'docs/template-format.md §4.4.

Sub Class_Globals
	Private mTokens As List
	Private mPos As Int
	Private mCtx As ReportEvalContext
End Sub

Public Sub Initialize

End Sub

Public Sub Eval (Expr As String, Ctx As ReportEvalContext) As Object
	mCtx = Ctx
	mTokens = Tokenize(Expr)
	mPos = 0
	If mTokens.Size = 0 Then Return ""
	Dim result As Object = ParseExpr
	Return result
End Sub

'--------------------------------------------------------------- tokenizer

Private Sub Tokenize (s As String) As List
	Dim out As List
	out.Initialize
	Dim i As Int = 0
	Do While i < s.Length
		Dim c As String = s.SubString2(i, i + 1)
		Dim code As Int = Asc(c)
		If c = " " Or c = Chr(9) Or c = Chr(10) Or c = Chr(13) Then
			i = i + 1
			Continue
		End If
		If (code >= 48 And code <= 57) Or c = "." Then
			Dim start As Int = i
			Do While i < s.Length
				Dim cc As String = s.SubString2(i, i + 1)
				Dim cd As Int = Asc(cc)
				If (cd >= 48 And cd <= 57) Or cc = "." Then
					i = i + 1
				Else
					Exit
				End If
			Loop
			Dim tok As ReportToken
			tok.Initialize("number", s.SubString2(start, i))
			out.Add(tok)
		Else If c = Chr(34) Then
			i = i + 1
			Dim sb As StringBuilder
			sb.Initialize
			Dim done As Boolean = False
			Do While i < s.Length And done = False
				Dim ch As String = s.SubString2(i, i + 1)
				If ch = Chr(34) Then
					i = i + 1
					done = True
				Else If ch = "\" Then
					i = i + 1
					If i < s.Length Then
						Dim esc As String = s.SubString2(i, i + 1)
						If esc = "n" Then
							sb.Append(Chr(10))
						Else If esc = "t" Then
							sb.Append(Chr(9))
						Else
							sb.Append(esc)
						End If
					End If
					i = i + 1
				Else
					sb.Append(ch)
					i = i + 1
				End If
			Loop
			Dim stok As ReportToken
			stok.Initialize("string", sb.ToString)
			out.Add(stok)
		Else If (code >= 65 And code <= 90) Or (code >= 97 And code <= 122) Or c = "_" Then
			Dim start2 As Int = i
			Do While i < s.Length
				Dim cc2 As String = s.SubString2(i, i + 1)
				Dim cd2 As Int = Asc(cc2)
				If (cd2 >= 65 And cd2 <= 90) Or (cd2 >= 97 And cd2 <= 122) Or (cd2 >= 48 And cd2 <= 57) Or cc2 = "_" Or cc2 = "." Then
					i = i + 1
				Else
					Exit
				End If
			Loop
			Dim word As String = s.SubString2(start2, i)
			Dim lower As String = word.ToLowerCase
			If lower = "and" Or lower = "or" Or lower = "not" Then
				Dim ktok As ReportToken
				ktok.Initialize("op", lower)
				out.Add(ktok)
			Else If lower = "true" Or lower = "false" Then
				Dim btok As ReportToken
				btok.Initialize("bool", lower)
				out.Add(btok)
			Else
				Dim itok As ReportToken
				itok.Initialize("ident", word)
				out.Add(itok)
			End If
		Else If c = "<" Then
			If i + 1 < s.Length Then
				Dim n1 As String = s.SubString2(i + 1, i + 2)
				If n1 = "=" Then
					Dim t1 As ReportToken
					t1.Initialize("op", "<=")
					out.Add(t1)
					i = i + 2
					Continue
				Else If n1 = ">" Then
					Dim t2 As ReportToken
					t2.Initialize("op", "<>")
					out.Add(t2)
					i = i + 2
					Continue
				End If
			End If
			Dim t3 As ReportToken
			t3.Initialize("op", "<")
			out.Add(t3)
			i = i + 1
		Else If c = ">" Then
			If i + 1 < s.Length And s.SubString2(i + 1, i + 2) = "=" Then
				Dim t4 As ReportToken
				t4.Initialize("op", ">=")
				out.Add(t4)
				i = i + 2
				Continue
			End If
			Dim t5 As ReportToken
			t5.Initialize("op", ">")
			out.Add(t5)
			i = i + 1
		Else If c = "=" Then
			Dim t6 As ReportToken
			t6.Initialize("op", "=")
			out.Add(t6)
			i = i + 1
		Else If c = "&" Or c = "+" Or c = "-" Or c = "*" Or c = "/" Or c = "(" Or c = ")" Or c = "," Then
			Dim t7 As ReportToken
			t7.Initialize("op", c)
			out.Add(t7)
			i = i + 1
		Else
			' unknown char: skip
			i = i + 1
		End If
	Loop
	Return out
End Sub

'--------------------------------------------------------------- parser

Private Sub ParseExpr As Object
	Return ParseOr
End Sub

Private Sub ParseOr As Object
	Dim left As Object = ParseAnd
	Do While MatchOp("or")
		Advance
		Dim right As Object = ParseAnd
		left = ToBool(left) Or ToBool(right)
	Loop
	Return left
End Sub

Private Sub ParseAnd As Object
	Dim left As Object = ParseNot
	Do While MatchOp("and")
		Advance
		Dim right As Object = ParseNot
		left = ToBool(left) And ToBool(right)
	Loop
	Return left
End Sub

Private Sub ParseNot As Object
	If MatchOp("not") Then
		Advance
		Dim v As Object = ParseNot
		Dim nb As Boolean = ToBool(v)
		Return (nb = False)
	End If
	Return ParseCmp
End Sub

Private Sub ParseCmp As Object
	Dim left As Object = ParseAdd
	Dim t As ReportToken = CurrentToken
	If t <> Null And t.TokenType = "op" Then
		Dim op As String = t.Value
		If op = "=" Or op = "<>" Or op = "<" Or op = ">" Or op = "<=" Or op = ">=" Then
			Advance
			Dim right As Object = ParseAdd
			Return Compare(left, op, right)
		End If
	End If
	Return left
End Sub

Private Sub ParseAdd As Object
	Dim left As Object = ParseMul
	Do While True
		Dim t As ReportToken = CurrentToken
		If t <> Null And t.TokenType = "op" And (t.Value = "+" Or t.Value = "-") Then
			Advance
			Dim right As Object = ParseMul
			If t.Value = "+" Then
				If IsNumericValue(left) And IsNumericValue(right) Then
					Dim dl As Double = left
					Dim dr As Double = right
					left = dl + dr
				Else
					left = ToString(left) & ToString(right)
				End If
			Else
				Dim dl2 As Double = 0
				Dim dr2 As Double = 0
				If IsNumericValue(left) Then dl2 = left
				If IsNumericValue(right) Then dr2 = right
				left = dl2 - dr2
			End If
		Else
			Exit
		End If
	Loop
	Return left
End Sub

Private Sub ParseMul As Object
	Dim left As Object = ParseConcat
	Do While True
		Dim t As ReportToken = CurrentToken
		If t <> Null And t.TokenType = "op" And (t.Value = "*" Or t.Value = "/") Then
			Advance
			Dim right As Object = ParseConcat
			Dim dl As Double = 0
			Dim dr As Double = 0
			If IsNumericValue(left) Then dl = left
			If IsNumericValue(right) Then dr = right
			If t.Value = "*" Then
				left = dl * dr
			Else
				If dr <> 0 Then left = dl / dr Else left = 0
			End If
		Else
			Exit
		End If
	Loop
	Return left
End Sub

Private Sub ParseConcat As Object
	Dim left As Object = ParseUnary
	Do While MatchOp("&")
		Advance
		Dim right As Object = ParseUnary
		left = ToString(left) & ToString(right)
	Loop
	Return left
End Sub

Private Sub ParseUnary As Object
	Dim t As ReportToken = CurrentToken
	If t <> Null And t.TokenType = "op" And (t.Value = "-" Or t.Value = "+") Then
		Advance
		Dim v As Object = ParseUnary
		If t.Value = "-" Then
			If IsNumericValue(v) Then
				Dim d As Double = v
				Return -d
			End If
			Return 0
		End If
		Return v
	End If
	Return ParsePrimary
End Sub

Private Sub ParsePrimary As Object
	Dim t As ReportToken = CurrentToken
	If t = Null Then Return Null

	If t.TokenType = "number" Then
		Advance
		Dim d As Double = 0
		Try
			d = t.Value
		Catch
			Log(LastException.Message)
			d = 0
		End Try
		Return d
	End If

	If t.TokenType = "string" Then
		Advance
		Return t.Value
	End If

	If t.TokenType = "bool" Then
		Advance
		Return (t.Value = "true")
	End If

	If t.TokenType = "op" And t.Value = "(" Then
		Advance
		Dim v As Object = ParseExpr
		If MatchOp(")") Then Advance
		Return v
	End If

	If t.TokenType = "ident" Then
		Dim name As String = t.Value
		' function call?
		If mPos + 1 < mTokens.Size Then
			Dim nextTok As ReportToken = mTokens.Get(mPos + 1)
			If nextTok.TokenType = "op" And nextTok.Value = "(" Then
				Advance ' ident
				Advance ' (
				Return ParseFunction(name)
			End If
		End If
		Advance
		Return ResolveIdentifier(name)
	End If

	Advance
	Return Null
End Sub

Private Sub ParseFunction (name As String) As Object
	Dim lower As String = name.ToLowerCase
	If lower = "if" Then
		Dim cond As Object = ParseExpr
		If MatchOp(",") Then Advance
		Dim a As Object = ParseExpr
		If MatchOp(",") Then Advance
		Dim b As Object = ParseExpr
		If MatchOp(")") Then Advance
		If ToBool(cond) Then Return a Else Return b
	End If
	' parse first arg
	Dim args As List
	args.Initialize
	If Not (CurrentToken <> Null And CurrentToken.TokenType = "op" And CurrentToken.Value = ")") Then
		args.Add(ParseExpr)
		Do While MatchOp(",")
			Advance
			args.Add(ParseExpr)
		Loop
	End If
	If MatchOp(")") Then Advance

	If lower = "len" Then
		If args.Size > 0 Then Return ToString(args.Get(0)).Length
		Return 0
	End If
	If lower = "upper" Then
		If args.Size > 0 Then Return ToString(args.Get(0)).ToUpperCase
		Return ""
	End If
	If lower = "lower" Then
		If args.Size > 0 Then Return ToString(args.Get(0)).ToLowerCase
		Return ""
	End If
	If lower = "trim" Then
		If args.Size > 0 Then Return ToString(args.Get(0)).Trim
		Return ""
	End If
	If lower = "round" Then
		If args.Size >= 2 Then
			Dim dec As Int = 0
			If IsNumericValue(args.Get(1)) Then dec = args.Get(1)
			If IsNumericValue(args.Get(0)) Then
				Dim d As Double = args.Get(0)
				Return ReportUnits.RoundTo(d, dec)
			End If
			Return 0
		End If
		If args.Size = 1 Then
			If IsNumericValue(args.Get(0)) Then
				Dim d2 As Double = args.Get(0)
				Return ReportUnits.RoundTo(d2, 0)
			End If
		End If
		Return 0
	End If
	If lower = "abs" Then
		If args.Size > 0 And IsNumericValue(args.Get(0)) Then
			Dim d3 As Double = args.Get(0)
			If d3 < 0 Then d3 = -d3
			Return d3
		End If
		Return 0
	End If
	If lower = "min" Then
		Dim m As Double = 0
		Dim have As Boolean = False
		For Each a As Object In args
			If IsNumericValue(a) Then
				Dim v As Double = a
				If have = False Or v < m Then
					m = v
					have = True
				End If
			End If
		Next
		If have Then Return m Else Return 0
	End If
	If lower = "max" Then
		Dim m2 As Double = 0
		Dim have2 As Boolean = False
		For Each a2 As Object In args
			If IsNumericValue(a2) Then
				Dim v2 As Double = a2
				If have2 = False Or v2 > m2 Then
					m2 = v2
					have2 = True
				End If
			End If
		Next
		If have2 Then Return m2 Else Return 0
	End If
	If lower = "formatdate" Then
		If args.Size >= 2 Then
			Dim pat As String = ToString(args.Get(1))
			If IsNumericValue(args.Get(0)) Then
				Dim ticks As Long = args.Get(0)
				Return FormatDate(ticks, pat)
			End If
			Return args.Get(0)
		End If
		If args.Size = 1 Then Return args.Get(0)
		Return ""
	End If
	Return Null
End Sub

'--------------------------------------------------------------- helpers

Private Sub CurrentToken As ReportToken
	If mPos >= mTokens.Size Then Return Null
	Return mTokens.Get(mPos)
End Sub

Private Sub Advance
	mPos = mPos + 1
End Sub

Private Sub MatchOp (op As String) As Boolean
	Dim t As ReportToken = CurrentToken
	If t = Null Then Return False
	If t.TokenType <> "op" Then Return False
	Return t.Value = op
End Sub

Private Sub ToBool (v As Object) As Boolean
	If v = Null Then Return False
	If v Is Boolean Then Return v
	If IsNumericValue(v) Then
		Dim d As Double = v
		Return d <> 0
	End If
	If v Is String Then
		Dim s As String = v
		If s.ToLowerCase = "true" Then Return True
		If s.Length > 0 Then Return True
	End If
	Return False
End Sub

Private Sub ToString (v As Object) As String
	If v = Null Then Return ""
	Return v
End Sub

Private Sub IsNumericValue (v As Object) As Boolean
	If v = Null Then Return False
	If v Is Boolean Then Return False
	If v Is String Then Return False
	Return True
End Sub

Private Sub Compare (left As Object, op As String, right As Object) As Object
	If op = "=" Then
		If left = Null And right = Null Then Return True
		If left = Null Or right = Null Then Return False
		Return (ToString(left) = ToString(right)) And (IsNumericValue(left) = IsNumericValue(right))
	End If
	If op = "<>" Then
		Dim eq As Boolean = Compare(left, "=", right)
		If eq Then Return False Else Return True
	End If
	Dim dl As Double = 0
	Dim dr As Double = 0
	If IsNumericValue(left) Then dl = left
	If IsNumericValue(right) Then dr = right
	Select Case op
		Case "<"
			Return dl < dr
		Case ">"
			Return dl > dr
		Case "<="
			Return dl <= dr
		Case ">="
			Return dl >= dr
	End Select
	' string comparison fallback
	Dim sl As String = ToString(left)
	Dim sr As String = ToString(right)
	Select Case op
		Case "<"
			Return sl.CompareTo(sr) < 0
		Case ">"
			Return sl.CompareTo(sr) > 0
		Case "<="
			Return sl.CompareTo(sr) <= 0
		Case ">="
			Return sl.CompareTo(sr) >= 0
	End Select
	Return False
End Sub

Private Sub ResolveIdentifier (name As String) As Object
	If name.IndexOf(".") >= 0 Then
		Dim parts As List = SplitDots(name)
		If parts.Size >= 2 Then
			Dim first As String = parts.Get(0)
			Dim field As String = parts.Get(1)
			If first.ToLowerCase = "param" Then
				Return mCtx.Params.Get(field)
			End If
			If first.ToLowerCase = "page" Then
				If field.ToLowerCase = "number" Then Return mCtx.PageNumber
				If field.ToLowerCase = "count" Then Return mCtx.PageCount
			End If
			Dim dsDef As ReportDataSetDef = mCtx.DataSets.Get(first) ' may be datasetdef or dataset
			' try dataset
			Dim ds As ReportDataSet = mCtx.DataSets.Get(first)
			If ds <> Null Then
				If ds.Kind = "single" Then
					If ds.SingleRecord.IsInitialized Then
						If ds.SingleRecord.ContainsKey(field) Then Return ds.SingleRecord.Get(field)
					End If
				Else
					If first = mCtx.CurrentDataSet And mCtx.CurrentRecord.IsInitialized Then
						If mCtx.CurrentRecord.ContainsKey(field) Then Return mCtx.CurrentRecord.Get(field)
					End If
					If mCtx.Aggregates.ContainsKey(field) Then Return mCtx.Aggregates.Get(field)
				End If
			End If
			If mCtx.Aggregates.ContainsKey(field) Then Return mCtx.Aggregates.Get(field)
		End If
	End If

	If mCtx.Aggregates.ContainsKey(name) Then Return mCtx.Aggregates.Get(name)
	If mCtx.CurrentRecord.IsInitialized Then
		If mCtx.CurrentRecord.ContainsKey(name) Then Return mCtx.CurrentRecord.Get(name)
	End If
	If mCtx.Params.ContainsKey(name) Then Return mCtx.Params.Get(name)
	Return Null
End Sub

Private Sub SplitDots (s As String) As List
	Dim out As List
	out.Initialize
	Dim cur As StringBuilder
	cur.Initialize
	Dim i As Int
	For i = 0 To s.Length - 1
		Dim c As String = s.SubString2(i, i + 1)
		If c = "." Then
			out.Add(cur.ToString)
			cur.Initialize
		Else
			cur.Append(c)
		End If
	Next
	If cur.Length > 0 Then out.Add(cur.ToString)
	Return out
End Sub

Private Sub FormatDate (ticks As Long, pattern As String) As String
	Dim y As Int = DateTime.GetYear(ticks)
	Dim mo As Int = DateTime.GetMonth(ticks)
	Dim da As Int = DateTime.GetDayOfMonth(ticks)
	Dim h As Int = DateTime.GetHour(ticks)
	Dim mi As Int = DateTime.GetMinute(ticks)
	Dim se As Int = DateTime.GetSecond(ticks)
	Dim out As String = pattern
	out = out.Replace("yyyy", Pad4(y))
	out = out.Replace("MM", Pad2(mo))
	out = out.Replace("dd", Pad2(da))
	out = out.Replace("HH", Pad2(h))
	out = out.Replace("mm", Pad2(mi))
	out = out.Replace("ss", Pad2(se))
	Return out
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
