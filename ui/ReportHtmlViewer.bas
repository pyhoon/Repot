B4J=true
Group=Export
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
Public Sub CreateView (Parent As B4XView)
	mBase = Parent
	BuildWebView
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

'Loads the HTML document. Returns False when the view was never created.
Public Sub LoadHtml (Html As String) As Boolean
	If mWv.IsInitialized = False Then Return False
	mWv.LoadHtml(Html)
	Return True
End Sub
