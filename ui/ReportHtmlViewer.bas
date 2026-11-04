B4J=true
Group=Export
ModulesStructureVersion=1
Type=Class
Version=10.7
@EndOfDesignText@
'Inline HTML preview for the report produced by the Repot facade.
'
'One shared module, two platform backends:
'  B4J desktop  -> fx.WebView (JavaFX), added to a Pane
'  B4A          -> android.webkit.WebView, added to a Panel/Activity
'
'This module ships in the optional RepotViewer.b4xlib, NOT in the core
'Repot.b4xlib: the core library must stay headless (StandardJava) so B4J
'server and console builds never pull in a UI stack.
'
'APIs verified before use:
'  jFX.xml    (B4J 10.7): WebView.Initialize(EventName), LoadHtml(HtmlString),
'                          RemoveNodeFromParent, Pane.AddNode/Width/Height
'  Core.xml   (B4A)     : WebView.Initialize(EventName), LoadHtml(Html),
'                          Panel.AddView(View, Left, Top, Width, Height)
'
'Usage:
'   Dim v As ReportHtmlViewer
'   v.Initialize(SomePanelOrPane)
'   v.LoadHtml(r.GetHtml)
'   v.Destroy        ' optional

Sub Class_Globals
	#If B4J
	Private mWv As WebView
	Private mPane As Pane
	#Else If B4A
	Private mWv As WebView
	Private mPanel As Panel
	Private mIndex As Int
	#End If
End Sub

'Adds a full-size WebView to Parent (a Pane on B4J, a Panel on B4A).
Public Sub Initialize (Parent As Object)
	#If B4J
	mPane = Parent
	mWv.Initialize("")
	mPane.AddNode(mWv, 0, 0, mPane.Width, mPane.Height)
	#Else If B4A
	mPanel = Parent
	mWv.Initialize("")
	mIndex = mPanel.NumberOfViews
	mPanel.AddView(mWv, 0, 0, mPanel.Width, mPanel.Height)
	#End If
End Sub

'Loads the HTML document asynchronously. Returns False when the viewer was
'never initialized (or the platform has no WebView implementation).
Public Sub LoadHtml (Html As String) As Boolean
	#If B4J
	If mWv.IsInitialized = False Then Return False
	mWv.LoadHtml(Html)
	Return True
	#Else If B4A
	If mWv.IsInitialized = False Then Return False
	mWv.LoadHtml(Html)
	Return True
	#Else
	Return False
	#End If
End Sub

'Removes the WebView from its parent. Safe to call more than once.
Public Sub Destroy
	#If B4J
	If mWv.IsInitialized Then mWv.RemoveNodeFromParent
	#Else If B4A
	If mWv.IsInitialized Then mPanel.RemoveViewAt(mIndex)
	#End If
End Sub
