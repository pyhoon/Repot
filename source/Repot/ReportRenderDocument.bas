B4J=true
Group=Render
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Immutable-by-convention output of layout.
'
'The document is versioned because its structure is compared by golden
'tests and consumed by every visual exporter. Applications receive it as
'an opaque handle; exporters read it. Do not mutate a document after Build
'has returned it.
'
'Version 1 shape and semantics are specified in docs/render-document.md.
Sub Class_Globals
	Public Version As Int
	Public Pages As List
End Sub

Public Sub Initialize
	Version = 1
	Pages.Initialize
End Sub

'Adds a page and assigns its 1-based index.
Public Sub AddPage (PageWidth As Double, PageHeight As Double) As ReportRenderPage
	Dim p As ReportRenderPage
	p.Initialize
	p.Width = PageWidth
	p.Height = PageHeight
	p.Index = Pages.Size + 1
	Pages.Add(p)
	Return p
End Sub

Public Sub PageCount As Int
	Return Pages.Size
End Sub

'Returns the page at a 1-based index, or Null when out of range.
Public Sub PageAt (PageIndex As Int) As ReportRenderPage
	If PageIndex < 1 Or PageIndex > Pages.Size Then Return Null
	Dim p As ReportRenderPage = Pages.Get(PageIndex - 1)
	Return p
End Sub
