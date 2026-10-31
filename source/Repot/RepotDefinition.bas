B4J=true
Group=Model
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Root template definition. This is the in-memory model shared by the JSON
'loader, the programmatic builder and (later) the designer.
Sub Class_Globals
	Public SchemaVersion As String
Public Id As String
Public Name As String
Public Description As String
Public Page As RepotPageSetup
Public Fonts As Map
Public Styles As Map
Public Parameters As List
Public DataSets As Map
Public Groups As List
Public Sections As List
Public Metadata As Map
Public SourceDir As String
End Sub

Public Sub Initialize
	SchemaVersion = RepotVersion.SupportedSchemaVersion
	Id = ""
	Name = ""
	Description = ""
	Page.Initialize
	Fonts.Initialize
	Styles.Initialize
	Parameters.Initialize
	DataSets.Initialize
	Groups.Initialize
	Sections.Initialize
	Metadata.Initialize
	SourceDir = ""
End Sub

Public Sub FontByName (FontName As String) As RepotFontDef
	If Fonts.ContainsKey(FontName) Then Return Fonts.Get(FontName)
	Return Null
End Sub

Public Sub StyleByName (StyleName As String) As RepotStyle
	If Styles.ContainsKey(StyleName) Then Return Styles.Get(StyleName)
	Return Null
End Sub

Public Sub ParameterByName (ParameterName As String) As RepotParameterDef
	For Each p As RepotParameterDef In Parameters
		If p.Name = ParameterName Then Return p
	Next
	Return Null
End Sub

Public Sub DataSetByName (DataSetName As String) As RepotDataSetDef
	If DataSets.ContainsKey(DataSetName) Then Return DataSets.Get(DataSetName)
	Return Null
End Sub

Public Sub GroupById (GroupId As String) As RepotGroupDef
	For Each g As RepotGroupDef In Groups
		If g.Id = GroupId Then Return g
	Next
	Return Null
End Sub

Public Sub SectionById (SectionId As String) As RepotSection
	For Each s As RepotSection In Sections
		If s.Id = SectionId Then Return s
	Next
	Return Null
End Sub

Public Sub SectionByType (SectionType As String) As RepotSection
	For Each s As RepotSection In Sections
		If s.SectionType = SectionType Then Return s
	Next
	Return Null
End Sub

Public Sub AllElements As List
	Dim l As List
	l.Initialize
	For Each s As RepotSection In Sections
		For Each e As RepotElement In s.Elements
			l.Add(e)
		Next
	Next
	Return l
End Sub

Public Sub ElementById (ElementId As String) As RepotElement
	For Each s As RepotSection In Sections
		Dim e As RepotElement = s.ElementById(ElementId)
		If e <> Null Then Return e
	Next
	Return Null
End Sub

Public Sub AllAggregates As List
	Dim l As List
	l.Initialize
	For Each name As String In DataSets.Keys
		Dim ds As RepotDataSetDef = DataSets.Get(name)
		For Each a As RepotAggregateDef In ds.Aggregates
			l.Add(a)
		Next
	Next
	For Each g As RepotGroupDef In Groups
		For Each a As RepotAggregateDef In g.Aggregates
			l.Add(a)
		Next
	Next
	Return l
End Sub

Public Sub AggregateByName (AggregateName As String) As RepotAggregateDef
	For Each a As RepotAggregateDef In AllAggregates
		If a.Name = AggregateName Then Return a
	Next
	Return Null
End Sub
