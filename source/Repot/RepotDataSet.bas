B4J=true
Group=Data
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Bound dataset supplied by the host application. Records are shallow maps of
'declared field names to typed values; missing fields are present as Null.

Sub Class_Globals
	Public Name As String
	Public Kind As String
	Public Definition As RepotDataSetDef
	Public Records As List
	Public SingleRecord As Map
	Public Supplied As Boolean
End Sub

Public Sub Initialize (Name1 As String, Kind1 As String, Definition1 As RepotDataSetDef)
	Name = Name1
	Kind = Kind1
	Definition = Definition1
	Records.Initialize
	SingleRecord.Initialize
	Supplied = False
End Sub

Public Sub Count As Int
	If Kind = "single" Then
		If SingleRecord.Size > 0 Then Return 1
		Return 0
	End If
	Return Records.Size
End Sub

Public Sub RecordAt (Index As Int) As Map
	If Kind = "single" Then Return SingleRecord
	If Index < 0 Or Index >= Records.Size Then Return Null
	Return Records.Get(Index)
End Sub
