B4A=true
Group=Core
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' SaveAs support via the Android Storage Access Framework (SAF).
'
' The engine never owns an Activity, and B4A does NOT deliver SAF results
' to Activity_Result. The host therefore creates an IOnActivityResult
' event on its own BA and waits for it (Erel's SaveAs pattern):
'
'   1) In the Activity module:
'        Private ion As Object
'
'        Dim i As Intent = ReportSaveAs.CreateDocumentIntent("application/pdf", "report.pdf")
'        Dim ba As JavaObject = GetBA
'        ion = ba.CreateEvent("anywheresoftware.b4a.IOnActivityResult", "ion", Null)
'        ReportSaveAs.StartForResult(ba, ion, i)
'        Wait For ion_Event (MethodName As String, Args() As Object)
'        If Args(0) = -1 Then ' RESULT_OK
'          Dim result As Intent = Args(1)
'          ReportSaveAs.CopyFileToUri(File.DirDefaultExternal, "invoice.pdf", result.GetData)
'        End If
'
'        Private Sub GetBA As JavaObject
'          Dim jo As JavaObject
'          Dim cls As String = Me
'          cls = cls.SubString("class ".Length)
'          jo.InitializeStatic(cls)
'          Return jo.GetField("processBA")
'        End Sub
'
' Facts verified against the installed libraries / Android SDK:
'  - ACTION_CREATE_DOCUMENT ("android.intent.action.CREATE_DOCUMENT", API 19+).
'  - EXTRA_TITLE = "android.intent.extra.TITLE"; mime via Intent.SetType.
'  - No permissions and no manifest entry are needed.
'  - RESULT_OK == -1 (android.app.Activity).
'  - Copying: ContentResolver.openOutputStream(Uri, "wt") ("wt" truncates a
'    file the picker pre-created); File.Copy2 / File.OpenInput are core.

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

'Starts the picker so the host gets an activity result. B4A does not
'deliver SAF results to Activity_Result; the host creates an
'IOnActivityResult event on its own BA and waits for it:
'
'    Dim ba As JavaObject = GetBA
'    ion = ba.CreateEvent("anywheresoftware.b4a.IOnActivityResult", "ion", Null)
'    ReportSaveAs.StartForResult(ba, ion, i)
'    Wait For ion_Event (MethodName As String, Args() As Object)
'    If Args(0) = -1 Then ReportSaveAs.CopyFileToUri(Dir, Name, Args(1).GetData)
'
'GetBA is: Dim jo As JavaObject = Me : cls = jo.SubString("class ".Length)
'           jo.InitializeStatic(cls) : Return jo.GetField("processBA")
Public Sub StartForResult (BaObj As Object, IonObj As Object, IntentObj As Object)
	#If B4A
	If BaObj = Null Or IonObj = Null Then Return
	Dim jo As JavaObject = BaObj
	jo.RunMethod("startActivityForResult", Array(IonObj, IntentObj))
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

'Saves a file straight into the public Downloads collection (API 29+)
'through MediaStore and returns the created content:// URI, or "" on
'failure. No picker and no Activity result, so it works even when the
'host cannot receive Activity_Result.
Public Sub SaveToDownloads (SrcDir As String, SrcName As String, Mime As String) As String
	#If B4A
	If File.Exists(SrcDir, SrcName) = False Then Return ""
	Try
		Dim ctx As JavaObject
		ctx.InitializeContext
		Dim resolver As JavaObject = ctx.RunMethod("getContentResolver", Null)
		Dim ms As JavaObject
		ms.InitializeStatic("android.provider.MediaStore$Downloads")
		Dim coll As Object = ms.GetField("EXTERNAL_CONTENT_URI")
		Dim values As JavaObject
		values.InitializeNewInstance("android.content.ContentValues", Null)
		values.RunMethod("put", Array("_display_name", SrcName))
		values.RunMethod("put", Array("mime_type", Mime))
		values.RunMethod("put", Array("relative_path", "Download/"))
		Dim uri As Object = resolver.RunMethod("insert", Array(coll, values))
		If uri = Null Then
			Log("SaveToDownloads: insert returned Null")
			Return ""
		End If
		Dim stream As OutputStream = resolver.RunMethod("openOutputStream", Array(uri))
		File.Copy2(File.OpenInput(SrcDir, SrcName), stream)
		stream.Close
		Dim jo As JavaObject = uri
		Return jo.RunMethod("toString", Null)
	Catch
		Log("SaveToDownloads failed: " & LastException.Message)
		Return ""
	End Try
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
		Dim stream As OutputStream = resolver.RunMethod("openOutputStream", Array(valid, "wt"))
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