B4J=true
Group=Data
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Binds host-supplied lists, single records and parameter values to a
'definition. The engine never opens a database or invokes SQL.
'
'Typed values are checked on the way in. Missing declared fields are Null;
'unknown fields produce a warning and are not copied.

Sub Class_Globals
	Public Diagnostics As RepotDiagnostics
	Public DataSets As Map
	Public Parameters As Map
	Private mDef As RepotDefinition
End Sub

Public Sub Initialize (Definition As RepotDefinition)
	Diagnostics.Initialize
	DataSets.Initialize
	Parameters.Initialize
	mDef = Definition
	ApplyDefaults
End Sub

Private Sub ApplyDefaults
	For Each p As RepotParameterDef In mDef.Parameters
		If p.HasDefault And Parameters.ContainsKey(p.Name) = False Then
			Dim v As Object = NormalizeValue(p.DefaultValue, p.DataType, p.Name, "default for parameter " & p.Name)
			Parameters.Put(p.Name, v)
		End If
	Next
End Sub

Public Sub SetDataSource (Name As String, Rows As List)
	Dim dsDef As RepotDataSetDef = mDef.DataSetByName(Name)
	If dsDef = Null Then
		Diagnostics.AddWarning("W-DATA-001", "dataset '" & Name & "' is not declared in the template", "/dataSets")
		Return
	End If
	If dsDef.Kind <> "rows" Then
		Diagnostics.AddError("E-DATA-001", "dataset '" & Name & "' is single and cannot be set from a list", "/dataSets/" & Name)
		Return
	End If
	If Rows = Null Then
		Diagnostics.AddError("E-DATA-002", "dataset '" & Name & "' has no rows", "/dataSets/" & Name)
		Return
	End If

	Dim ds As RepotDataSet
	ds.Initialize(Name, "rows", dsDef)
	ds.Supplied = True
	For i = 0 To Rows.Size - 1
		Dim o As Object = Rows.Get(i)
		If (o Is Map) = False Then
			Diagnostics.AddError("E-DATA-003", "dataset '" & Name & "' record " & i & " is not an object", "/dataSets/" & Name)
			Continue
		End If
		ds.Records.Add(NormalizeRecord(dsDef, o, "/dataSets/" & Name & "/" & i))
	Next
	DataSets.Put(Name, ds)
End Sub

Public Sub SetDataSourceSingle (Name As String, Record As Map)
	Dim dsDef As RepotDataSetDef = mDef.DataSetByName(Name)
	If dsDef = Null Then
		Diagnostics.AddWarning("W-DATA-001", "dataset '" & Name & "' is not declared in the template", "/dataSets")
		Return
	End If
	If dsDef.Kind <> "single" Then
		Diagnostics.AddError("E-DATA-004", "dataset '" & Name & "' is a row dataset and cannot be set from a single record", "/dataSets/" & Name)
		Return
	End If
	If Record = Null Then
		Diagnostics.AddError("E-DATA-002", "dataset '" & Name & "' has no record", "/dataSets/" & Name)
		Return
	End If

	Dim ds As RepotDataSet
	ds.Initialize(Name, "single", dsDef)
	ds.Supplied = True
	ds.SingleRecord = NormalizeRecord(dsDef, Record, "/dataSets/" & Name)
	DataSets.Put(Name, ds)
End Sub

Public Sub SetParameter (Name As String, Value As Object)
	Dim p As RepotParameterDef = mDef.ParameterByName(Name)
	If p = Null Then
		Diagnostics.AddWarning("W-DATA-002", "parameter '" & Name & "' is not declared in the template", "/parameters")
		Parameters.Put(Name, Value)
		Return
	End If
	Dim v As Object = NormalizeValue(Value, p.DataType, Name, "parameter " & Name)
	Parameters.Put(Name, v)
End Sub

Public Sub SetParameterInt (Name As String, Value As Int)
	SetParameter(Name, Value)
End Sub

Public Sub SetParameterDouble (Name As String, Value As Double)
	SetParameter(Name, Value)
End Sub

Public Sub SetParameterBool (Name As String, Value As Boolean)
	SetParameter(Name, Value)
End Sub

Public Sub SetParameterDate (Name As String, Value As Long)
	SetParameter(Name, Value)
End Sub

Public Sub GetDataSet (Name As String) As RepotDataSet
	If DataSets.ContainsKey(Name) Then Return DataSets.Get(Name)
	Return Null
End Sub

Public Sub ParameterValue (Name As String) As Object
	If Parameters.ContainsKey(Name) Then Return Parameters.Get(Name)
	Return Null
End Sub

Public Sub Validate As Boolean
	For Each name As String In mDef.DataSets.Keys
		If DataSets.ContainsKey(name) = False Then
			Diagnostics.AddError("E-DATA-010", "dataset '" & name & "' was not supplied by the application", "/dataSets/" & name)
		End If
	Next
	For Each p As RepotParameterDef In mDef.Parameters
		If p.Required Then
			If Parameters.ContainsKey(p.Name) = False Then
				Diagnostics.AddError("E-DATA-011", "required parameter '" & p.Name & "' was not supplied", "/parameters/" & p.Name)
			Else If Parameters.Get(p.Name) = Null Then
				Diagnostics.AddError("E-DATA-011", "required parameter '" & p.Name & "' is null", "/parameters/" & p.Name)
			End If
		End If
	Next
	If Diagnostics.HasErrors Then Return False
	Return True
End Sub

'--------------------------------------------------------------- values

Private Sub NormalizeRecord (dsDef As RepotDataSetDef, Source As Map, Path As String) As Map
	Dim out As Map
	out.Initialize
	For Each f As RepotFieldDef In dsDef.Fields
		If Source.ContainsKey(f.Name) Then
			Dim v As Object = NormalizeValue(Source.Get(f.Name), f.DataType, f.Name, Path & "/" & f.Name)
			out.Put(f.Name, v)
		Else
			out.Put(f.Name, Null)
		End If
	Next
	For Each k As String In Source.Keys
		If dsDef.FieldByName(k) = Null Then
			Diagnostics.AddWarning("W-DATA-003", "undeclared field '" & k & "' ignored", Path)
		End If
	Next
	Return out
End Sub

Private Sub NormalizeValue (Value As Object, DataType As String, FieldName As String, Where As String) As Object
	If Value = Null Then Return Null

	If DataType = "string" Then
		If Value Is String Then Return Value
		Diagnostics.AddError("E-DATA-020", Where & ": expected string for '" & FieldName & "'", "")
		Return Null
	Else If DataType = "integer" Then
		If IsNumber(Value) Then
			Dim d As Double = Value
			If Floor(d) <> d Then
				Diagnostics.AddError("E-DATA-021", Where & ": expected integer for '" & FieldName & "'", "")
				Return Null
			End If
			Return d
		End If
		Diagnostics.AddError("E-DATA-020", Where & ": expected integer for '" & FieldName & "'", "")
		Return Null
	Else If DataType = "decimal" Then
		If IsNumber(Value) Then
			Dim d2 As Double = Value
			Return d2
		End If
		Diagnostics.AddError("E-DATA-020", Where & ": expected decimal for '" & FieldName & "'", "")
		Return Null
	Else If DataType = "boolean" Then
		If Value Is Boolean Then Return Value
		Diagnostics.AddError("E-DATA-020", Where & ": expected boolean for '" & FieldName & "'", "")
		Return Null
	Else If DataType = "date" Or DataType = "datetime" Then
		If Value Is String Then Return Value
		If IsNumber(Value) Then Return Value
		Diagnostics.AddError("E-DATA-020", Where & ": expected date/datetime for '" & FieldName & "'", "")
		Return Null
	End If

	Diagnostics.AddError("E-DATA-022", Where & ": unknown declared type '" & DataType & "'", "")
	Return Null
End Sub
