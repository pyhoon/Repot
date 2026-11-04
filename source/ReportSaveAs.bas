B4A=true
Group=Core
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' SaveAs support via the Android Storage Access Framework (SAF).
'
' The engine never owns an Activity, so the host wires two pieces:
'
'   1) Start the picker:
'        Dim i As Intent = ReportSaveAs.CreateDocumentIntent("application/pdf", "report.pdf")
'        ReportSaveAs.StartForResult(i, ReportSaveAs.DefaultRequestCode)
'
'   2) In the Activity module:
'        Sub Activity_Result (RequestCode As Int, ResultCode As Int, Data As Object)
'          Dim uri As String = ReportSaveAs.HandleActivityResult(RequestCode, ResultCode, Data)
'          If uri <> "" Then
'            ReportSaveAs.CopyFileToUri(File.DirDefaultExternal, "invoice.pdf", uri)
'          End If
'        End Sub
'
' Facts verified against the installed libraries / Android SDK:
'  - ACTION_CREATE_DOCUMENT ("android.intent.action.CREATE_DOCUMENT", API 19+).
'  - EXTRA_TITLE = "android.intent.extra.TITLE"; mime via Intent.SetType.
'  - Activity_Result data is an Intent; Intent.GetData returns the
'    chosen content:// Uri as a string (core.xml).
'  - RESULT_OK == -1 (android.app.Activity).
'  - Copying: ContentResolver.openOutputStream(Uri) via JavaObject;
'    File.Copy2 / File.OpenInput are core.
'  - No permissions are required for ACTION_CREATE_DOCUMENT.

Sub Process_Globals
	Public DefaultRequestCode As Int = 7001
	Private mArmed As Int = 0
	Private Const RESULT_OK As Int = -1 ' android.app.Activity.RESULT_OK
End Sub

'Builds a SAF CreateDocument intent. Mime is the document type (for
'example "application/pdf"); Title is the suggested file name shown in the
'picker. Returns an Intent (B4A) or Null (B4J); callers treat the result
'as Object and cast on B4A: Dim i As Intent = ReportSaveAs.CreateDocumentIntent(...).
Public Sub CreateDocumentIntent (Mime As String, Title As String) As Object
	#If B4A
	Dim i As Intent
	i.Initialize("android.intent.action.CREATE_DOCUMENT", "")
	i.SetType(Mime)
	i.PutExtra("android.intent.extra.TITLE", Title)
	i.AddCategory("android.intent.category.OPENABLE")
	Return i
	#Else
	Return Null
	#End If
End Sub

'Starts the intent for a result on the current activity and arms this
'handler for that request code (reflection reaches
'Activity.startActivityForResult). Hosts that launch the intent
'themselves call ArmCode first. On B4A pass an Intent; any other value is
'ignored.
Public Sub StartForResult (I As Object, Code As Int)
	#If B4A
	mArmed = Code
	Dim intent As Intent = I
	Dim jo As JavaObject
	jo.InitializeContext
	jo.RunMethod("startActivityForResult", Array(intent, Code))
	#End If
End Sub

'Arms the handler for a manually launched request code.
Public Sub ArmCode (Code As Int)
	mArmed = Code
End Sub

'Pass through from the host's Activity_Result. Returns the chosen
'content:// URI when both codes match and the result is OK, or "" when
'the user cancelled or the request belongs to another selector.
Public Sub HandleActivityResult (RequestCode As Int, ResultCode As Int, Data As Object) As String
	#If B4A
	If RequestCode <> mArmed Or ResultCode <> RESULT_OK Then Return ""
	If Data = Null Then Return ""
	Dim in As Intent = Data
	Dim uri As String = in.GetData
	Return uri
	#Else
	Return ""
	#End If
End Sub

'Copies a file from app-visible storage into the content URI chosen in
'the SAF picker (openOutputStream, no permissions needed).
Public Sub CopyFileToUri (SrcDir As String, SrcName As String, Uri As String) As Boolean
	#If B4A
	If Uri = "" Then Return False
	Try
		Dim ctx As JavaObject
		ctx.InitializeContext
		Dim resolver As JavaObject = ctx.RunMethod("getContentResolver", Null)
		Dim uriJO As JavaObject
		uriJO.InitializeStatic("android.net.Uri")
		Dim valid As JavaObject = uriJO.RunMethod("parse", Array(Uri))
		Dim stream As OutputStream = resolver.RunMethod("openOutputStream", Array(valid))
		File.Copy2(File.OpenInput(SrcDir, SrcName), stream)
		stream.Close
		Return True
	Catch
		Log("CopyFileToUri failed: " & LastException.Message)
		Return False
	End Try
	#Else
	Return False
	#End If
End Sub