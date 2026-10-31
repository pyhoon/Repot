B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Declared aggregate. Scope is either "dataset" or "group"; ScopeId names the
'declaring dataset or group. Names are document-unique by validation.
Sub Class_Globals
	Public Name As String
	Public FunctionName As String
	Public FieldName As String
	Public Scope As String
	Public ScopeId As String
End Sub

Public Sub Initialize
	Name = ""
	FunctionName = ""
	FieldName = ""
	Scope = ""
	ScopeId = ""
End Sub
