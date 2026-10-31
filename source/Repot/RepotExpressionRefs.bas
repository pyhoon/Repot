B4J=true
Group=Core
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
'Extraction and lexical scanning for braced expressions.
'
'The full expression parser and evaluator arrive in M6. M1 validates that
'every reference can resolve, using the same identifier grammar the parser
'will use.

Sub Process_Globals

End Sub

Public Sub Extract (Text As String, Diagnostics As RepotDiagnostics, Path As String) As List
	Dim out As List
	out.Initialize
	Dim i As Int = 0
	Do While i < Text.Length
		Dim c As String = Text.SubString2(i, i + 1)
		If c = "{" Then
			Dim depth As Int = 1
			Dim start As Int = i + 1
			Dim j As Int = start
			Do While j < Text.Length
				Dim c2 As String = Text.SubString2(j, j + 1)
				If c2 = "{" Then
					depth = depth + 1
				Else If c2 = "}" Then
					depth = depth - 1
					If depth = 0 Then Exit
				End If
				j = j + 1
			Loop
			If depth <> 0 Then
				Diagnostics.AddError("E-EXPR-002", "unbalanced '{' in expression", Path)
				Return out
			End If
			Dim expr As String = Text.SubString2(start, j)
			If expr.Trim.Length = 0 Then
				Diagnostics.AddError("E-EXPR-003", "empty expression", Path)
			Else
				out.Add(expr)
			End If
			i = j + 1
		Else If c = "}" Then
			Diagnostics.AddError("E-EXPR-002", "unbalanced '}' in expression", Path)
			Return out
		Else
			i = i + 1
		End If
	Loop
	Return out
End Sub

'Returns the identifiers in one expression, skipping literals, numbers and
'operators. Reports characters that the expression grammar cannot accept.
Public Sub Identifiers (Expression As String, Diagnostics As RepotDiagnostics, Path As String) As List
	Dim out As List
	out.Initialize
	Dim i As Int = 0
	Do While i < Expression.Length
		Dim c As String = Expression.SubString2(i, i + 1)
		Dim code As Int = Asc(c)

		If code <= 32 Then
			i = i + 1
		Else If c = Chr(34) Then
			' String literal. A doubled quote is an escaped quote.
			i = i + 1
			Dim closed As Boolean = False
			Do While i < Expression.Length
				Dim q As String = Expression.SubString2(i, i + 1)
				If q = Chr(34) Then
					If i + 1 < Expression.Length Then
						If Expression.SubString2(i + 1, i + 2) = Chr(34) Then
							i = i + 2
							Continue
						End If
					End If
					closed = True
					i = i + 1
					Exit
				End If
				i = i + 1
			Loop
			If closed = False Then
				Diagnostics.AddError("E-EXPR-004", "unterminated string literal in expression", Path)
				Return out
			End If
		Else If code >= 48 And code <= 57 Then
			Dim seenDot As Boolean = False
			Do While i < Expression.Length
				Dim d As String = Expression.SubString2(i, i + 1)
				Dim dc As Int = Asc(d)
				If dc >= 48 And dc <= 57 Then
					i = i + 1
				Else If d = "." And seenDot = False Then
					seenDot = True
					i = i + 1
				Else
					Exit
				End If
			Loop
		Else If IsIdentifierStart(c) Then
			Dim start As Int = i
			Do While i < Expression.Length
				Dim ch As String = Expression.SubString2(i, i + 1)
				If IsIdentifierPart(ch) Then
					i = i + 1
				Else
					Exit
				End If
			Loop
			out.Add(Expression.SubString2(start, i))
		Else If "(),+-*/=<>!&?:".IndexOf(c) >= 0 Then
			i = i + 1
		Else If c = "{" Or c = "}" Then
			'Braces are expression-reference delimiters, not operators.
			i = i + 1
		Else
			Diagnostics.AddError("E-EXPR-001", "unexpected character '" & c & "' in expression", Path)
			Return out
		End If
	Loop
	Return out
End Sub

Private Sub IsIdentifierStart (c As String) As Boolean
	Dim code As Int = Asc(c)
	If code >= 65 And code <= 90 Then Return True
	If code >= 97 And code <= 122 Then Return True
	Return c = "_"
End Sub

Private Sub IsIdentifierPart (c As String) As Boolean
	If IsIdentifierStart(c) Then Return True
	Dim code As Int = Asc(c)
	If code >= 48 And code <= 57 Then Return True
	Return c = "."
End Sub
