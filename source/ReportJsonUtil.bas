B4J=true
Group=Core
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
'Small JSON helpers shared by the loader, writer and tests.
'They accept Object values because JSONParser returns loosely typed data.

Sub Process_Globals

End Sub

Public Sub NewMap As Map
	Dim m As Map
	m.Initialize
	Return m
End Sub

Public Sub NewList As List
	Dim l As List
	l.Initialize
	Return l
End Sub

Public Sub AsMap (Value As Object) As Map
	Dim m As Map
	m.Initialize
	If Value Is Map Then m = Value
	Return m
End Sub

Public Sub AsList (Value As Object) As List
	Dim l As List
	l.Initialize
	If Value Is List Then l = Value
	Return l
End Sub

Public Sub ValueAt (o As Object, Key As String) As Object
	If o Is Map Then
		Dim m As Map = o
		If m.ContainsKey(Key) Then Return m.Get(Key)
	End If
	Return Null
End Sub

Public Sub HasKey (o As Object, Key As String) As Boolean
	If o Is Map Then
		Dim m As Map = o
		Return m.ContainsKey(Key)
	End If
	Return False
End Sub

Public Sub MapAt (o As Object, Key As String) As Map
	Return AsMap(ValueAt(o, Key))
End Sub

Public Sub ListAt (o As Object, Key As String) As List
	Return AsList(ValueAt(o, Key))
End Sub

Public Sub StringAt (o As Object, Key As String, Default As String) As String
	Dim v As Object = ValueAt(o, Key)
	If v = Null Then Return Default
	If v Is String Then Return v
	If IsNumber(v) Then Return v
	If v Is Boolean Then Return v
	Return Default
End Sub

Public Sub BoolAt (o As Object, Key As String, Default As Boolean) As Boolean
	Dim v As Object = ValueAt(o, Key)
	If v = Null Then Return Default
	If v Is Boolean Then Return v
	Return Default
End Sub

Public Sub DoubleAt (o As Object, Key As String, Default As Double) As Double
	Dim v As Object = ValueAt(o, Key)
	If v = Null Then Return Default
	If IsNumber(v) Then
		Dim d As Double = v
		Return d
	End If
	Return Default
End Sub

Public Sub IntAt (o As Object, Key As String, Default As Int) As Int
	Dim v As Object = ValueAt(o, Key)
	If v = Null Then Return Default
	If IsNumber(v) Then
		Dim i As Int = v
		Return i
	End If
	Return Default
End Sub

Public Sub StringList (Value As Object) As List
	Dim out As List
	out.Initialize
	Dim l As List = AsList(Value)
	For Each o As Object In l
		If o <> Null Then out.Add(o)
	Next
	Return out
End Sub

Public Sub Delimited (Values As List) As String
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("|")
	For Each v As Object In Values
		If v <> Null Then sb.Append(v).Append("|")
	Next
	Return sb.ToString
End Sub

'Returns a JSON string literal, including the surrounding quotes.
Public Sub JsonQuote (s As String) As String
	Return Chr(34) & Escape(s) & Chr(34)
End Sub

Public Sub Escape (s As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To s.Length - 1
		Dim c As String = s.SubString2(i, i + 1)
		Dim code As Int = Asc(c)
		If c = Chr(34) Then
			sb.Append(Chr(92)).Append(Chr(34))
		Else If c = Chr(92) Then
			sb.Append(Chr(92)).Append(Chr(92))
		Else If c = Chr(10) Then
			sb.Append(Chr(92)).Append("n")
		Else If c = Chr(13) Then
			sb.Append(Chr(92)).Append("r")
		Else If c = Chr(9) Then
			sb.Append(Chr(92)).Append("t")
		Else If code < 32 Then
			sb.Append(Chr(92)).Append("u00").Append(HexByte(code))
		Else
			sb.Append(c)
		End If
	Next
	Return sb.ToString
End Sub

Public Sub HexByte (Value As Int) As String
	Dim digits As String = "0123456789abcdef"
	Dim hi As Int = Floor(Value / 16)
	Dim lo As Int = Value - hi * 16
	Return digits.SubString2(hi, hi + 1) & digits.SubString2(lo, lo + 1)
End Sub
