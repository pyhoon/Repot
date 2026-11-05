B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Inline HTML preview of a Repot report, as a B4X custom view.
'
'Add it in the Layout Designer like any other view (it appears in the
'Custom Views list once RepotViewer.b4xlib is installed). In code:
'
'   Dim v As ReportHtmlViewer
'   v.Initialize(Me, "viewer")
'   v.CreateView(pnl)          ' pnl As B4XView
'   v.LoadHtml(r.GetHtml)
'
'Backends (selected by the compiler):
'   B4J -> fx.WebView            B4A -> android.webkit.WebView
'
'APIs verified before use:
'   jFX.xml  (B4J 10.7): WebView.Initialize(EventName), LoadHtml(HtmlString),
'                        PageFinished(Url)
'   Core.xml (B4A):      WebView.Initialize(EventName), LoadHtml(Html),
'                        PageFinished(Url)

#Event: PageFinished (Url As String)

Sub Class_Globals
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Public mBase As B4XView
	Public Tag As Object
	Private mWv As WebView
	Private mHtml As String
	Private mPageWidthPt As Double
	Private mFitWidth As Double
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
End Sub

'Base type must be Object (Layout Designer entry point).
Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	Tag = mBase.Tag
	mBase.Tag = Me
	BuildWebView
End Sub

'Code entry point: parent the viewer on an existing panel/pane.
'Public Sub CreateView (Parent As B4XView)
'	mBase = Parent
'	BuildWebView
'End Sub

Private Sub Base_Resize (Width As Double, Height As Double)
	'Re-fit when the view width changed noticeably (and something is loaded).
	If mHtml = "" Then Return
	Dim w As Double = CssWidth
	If w <= 0 Then Return
	If mFitWidth > 0 And Abs(w - mFitWidth) < mFitWidth * 0.02 Then Return
	ShowFitted
End Sub

'View width in CSS pixels (B4A views are in device pixels).
Private Sub CssWidth As Double
	Dim w As Double = mBase.Width
	#If B4A
	w = w / GetDeviceLayoutValues.Scale
	#End If
	Return w
End Sub

Private Sub BuildWebView
	mWv.Initialize("mWv")
	mBase.AddView(mWv, 0, 0, mBase.Width, mBase.Height)
End Sub

Private Sub mWv_PageFinished (Url As String)
	If mCallBack = Null Then Return
	If mEventName = "" Then Return
	CallSub2(mCallBack, mEventName & "_PageFinished", Url)
End Sub

Public Sub getWebview As WebView
	Return mWv
End Sub

'Loads the HTML document. Returns False when the view was never created.
Public Sub LoadHtml (Html As String) As Boolean
	If mWv.IsInitialized = False Then Return False
	mHtml = Html
	mPageWidthPt = FindPageWidthPt(Html)
	ShowFitted
	Return True
End Sub

'Loads the document scaled so the page fits the view width (never upscales).
Private Sub ShowFitted
	If mWv.IsInitialized = False Then Return
	Dim w As Double = CssWidth
	If w <= 0 Then w = mBase.Width
	mFitWidth = w
	mWv.LoadHtml(ApplyFit(mHtml))
End Sub

'Adds a zoom rule when the page is wider than the view. CSS zoom reflows,
'so page height and page breaks stay consistent; the exported file is not
'modified (the rule is only added to the string handed to the WebView).
Private Sub ApplyFit (Html As String) As String
	If mFitWidth <= 0 Or mPageWidthPt <= 0 Then Return Html
	Dim pagePx As Double = mPageWidthPt * 96 / 72 ' pt -> CSS px
	Dim k As Double = mFitWidth / pagePx
	If k >= 1 Then Return Html
	Dim idx As Int = Html.IndexOf("</head>")
	If idx = -1 Then Return Html
	Dim rule As String = "<style>body{margin:0;background:#dcdcdc}.page{zoom:" & KText(k) & "}</style>"
	Return Html.SubString2(0, idx) & rule & Html.SubString(idx)
End Sub

'Number with up to 4 decimals and a dot (CSS needs a dot whatever the locale).
Private Sub KText (Value As Double) As String
	Dim s As String = NumberFormat2(Value, 1, 4, 4, False)
	Return s.Replace(",", ".")
End Sub

'First page width in points, read from the .page div the exporter writes.
Private Sub FindPageWidthPt (Html As String) As Double
	Dim marker As String = "style=""width:"
	Dim i As Int = Html.IndexOf(marker)
	If i = -1 Then Return 0
	Dim rest As String = Html.SubString(i + marker.Length)
	Dim j As Int = rest.IndexOf("pt")
	If j = -1 Then Return 0
	Dim s As String = rest.SubString2(0, j)
	Dim v As Double = s
	Return v
End Sub
