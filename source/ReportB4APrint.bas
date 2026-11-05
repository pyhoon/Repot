B4A=true
Group=Export
ModulesStructureVersion=1
Type=Code
Version=10.7
@EndOfDesignText@
' B4A-only module: render an HTML document to a PDF file via the Android
' WebView (rasterised, per docs/compatibility.md Tier 2).
' Async: call PrintHtmlToPdf(...); the PrintComplete(Success, Path) event
' fires on completion. Use with B4A Wait For.

Sub Process_Globals
	#If B4A
	Private mSourceDir As String
	#Else
	' B4J compiles this module to an empty shell; the real code is B4A-only.
	#End If
End Sub

#If B4A

' Vector PDF via the Printing library's PdfDocument canvas (synchronous).
Public Sub PrintVectorPdf(Doc As ReportRenderDocument, OutputPath As String, SourceDir As String) As Boolean
	mSourceDir = SourceDir
	Dim pdf As PdfDocument
	pdf.Initialize
	Dim i As Int
	For i = 0 To Doc.PageCount - 1
		Dim page As ReportRenderPage = Doc.PageAt(i + 1)
		pdf.StartPage(page.Width, page.Height)
		Dim canvas As Canvas = pdf.Canvas
		Dim k As Int
		For k = 0 To page.Ops.Size - 1
			Dim op As ReportDrawOp = page.Ops.Get(k)
			DrawOp(canvas, op)
		Next
		pdf.FinishPage
	Next
	Dim idx As Int = OutputPath.LastIndexOf("\")
	Dim idx2 As Int = OutputPath.LastIndexOf("/")
	If idx2 > idx Then idx = idx2
	Dim dir As String = OutputPath.SubString2(0, idx)
	Dim name As String = OutputPath.SubString(idx + 1)
	Dim out As OutputStream = File.OpenOutput(dir, name, False)
	pdf.WriteToStream(out)
	out.Close
	pdf.Close
	' Existence alone is not success: the stream is created before anything
	' is written, so a failed write leaves a 0-byte file that "exists".
	If File.Size(dir, name) <= 0 Then
		Log("PrintVectorPdf: wrote a 0-byte PDF to " & OutputPath)
		Return False
	End If
	Return True
End Sub

Private Sub DrawOp (canvas As Canvas, op As ReportDrawOp)
	Select Case op.OpType
		Case "text"
			Dim tf As Typeface
			Dim style As Int = Typeface.STYLE_NORMAL
			If op.Bold And op.Italic Then
				style = Typeface.STYLE_BOLD_ITALIC
			Else If op.Bold Then
				style = Typeface.STYLE_BOLD
			Else If op.Italic Then
				style = Typeface.STYLE_ITALIC
			End If
			Dim base As Typeface
			Dim f As String = op.FontName.ToLowerCase
			If f.Contains("serif") Or f.Contains("times") Then
				base = Typeface.SERIF
			Else If f.Contains("mono") Or f.Contains("courier") Then
				base = Typeface.MONOSPACE
			Else
				base = Typeface.SANS_SERIF
			End If
			tf = Typeface.CreateNew(base, style)
			Dim baseline As Double = op.Y + op.Baseline
			' CanvasWrapper treats TextSize as dp; the PDF canvas is 72 dpi.
			Dim ptSize As Double = op.FontSize / GetDeviceLayoutValues.Scale
			Dim anchorX As Double = op.X
			Dim al As String = op.Align.ToUpperCase
			If al = "RIGHT" Then
				anchorX = op.X + op.Width
			Else If al = "CENTER" Then
				anchorX = op.X + op.Width / 2
			End If
			' Clip to the element box so small font-metric differences cannot
			' spill into the next column (the layout engine already wrapped).
			Dim clipTop As Double = op.Y - 2
			Dim clipBottom As Double = op.Y + op.Height + 2
			Dim clipRight As Double = op.X + op.Width
			Dim clipPath As Path
			clipPath.Initialize(op.X, clipTop)
			clipPath.LineTo(clipRight, clipTop)
			clipPath.LineTo(clipRight, clipBottom)
			clipPath.LineTo(op.X, clipBottom)
			clipPath.LineTo(op.X, clipTop)
			canvas.ClipPath(clipPath)
			canvas.DrawText(op.Text, anchorX, baseline, tf, ptSize, ParseColor(op.Colour), al)
			canvas.RemoveClip
		Case "line"
			canvas.DrawLine(op.X, op.Y, op.X2, op.Y2, ParseColor(op.Colour), op.LineWidth)
		Case "rect"
			Dim c As Int = ParseColor(op.FillColour)
			Dim r As Rect
			r.Initialize(op.X, op.Y, op.X + op.Width, op.Y + op.Height)
			If op.FillColour <> "" And op.FillColour <> "transparent" Then
				canvas.DrawRect(r, c, True, 0)
			End If
			If op.LineWidth > 0 Then
				canvas.DrawRect(r, ParseColor(op.Colour), False, op.LineWidth)
			End If
		Case "image"
			Try
				Dim bmp As Bitmap = LoadBitmap(mSourceDir, op.ResourcePath)
				Dim dr As Rect
				dr.Initialize(op.X, op.Y, op.X + op.Width, op.Y + op.Height)
				canvas.DrawBitmap(bmp, Null, dr)
			Catch
				Log("image err: " & LastException.Message)
			End Try
		Case "clip"
			Dim clipR2 As Double = op.X + op.Width
			Dim clipB2 As Double = op.Y + op.Height
			Dim cp As Path
			cp.Initialize(op.X, op.Y)
			cp.LineTo(clipR2, op.Y)
			cp.LineTo(clipR2, clipB2)
			cp.LineTo(op.X, clipB2)
			cp.LineTo(op.X, op.Y)
			canvas.ClipPath(cp)
		Case "restore"
			canvas.RemoveClip
	End Select
End Sub

Private Sub ParseColor (hex As String) As Int
	If hex = "" Then Return Colors.Black
	If hex.StartsWith("#") Then hex = hex.SubString(1)
	If hex.Length = 6 Then
		Dim r As Int = Bit.ParseInt(hex.SubString2(0,2), 16)
		Dim g As Int = Bit.ParseInt(hex.SubString2(2,4), 16)
		Dim b As Int = Bit.ParseInt(hex.SubString2(4,6), 16)
		Return Colors.RGB(r,g,b)
	End If
	Return Colors.Black
End Sub

Public Sub PrintHtmlToPdf(Html As String, OutputPath As String, Width As Int, Height As Int)
	Dim jo As JavaObject
	jo.InitializeStatic("b4a.example.reportb4aprint")
	jo.RunMethod("printToPdf", Array(Html, OutputPath, Width, Height))
End Sub

#If B4A
#If Java
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.print.pdf.PrintedPdfDocument;
import android.print.PrintAttributes;
import android.graphics.Picture;
import android.os.Handler;
import android.os.Looper;
import java.io.File;
import java.io.FileOutputStream;
import java.util.concurrent.CountDownLatch;

public static void printToPdf(final String html, final String outputPath, final int width, final int height) {
	final android.content.Context ctx;
	try {
		Class<?> at = Class.forName("android.app.ActivityThread");
		java.lang.reflect.Method m = at.getMethod("currentApplication");
		ctx = (android.content.Context) m.invoke(null);
	} catch (Exception e) {
		android.util.Log.e("RepotPrint", "ctx err", e);
		try { getBA().raiseEventFromUI(null, "printcomplete", false, outputPath); } catch (Exception ignored) {}
		return;
	}
	if (ctx == null) {
		android.util.Log.e("RepotPrint", "ctx is null");
		try { getBA().raiseEventFromUI(null, "printcomplete", false, outputPath); } catch (Exception ignored) {}
		return;
	}


	new Thread(new Runnable() {
		public void run() {
			final boolean[] result = new boolean[1];
			final WebView[] wvHolder = new WebView[1];
			final boolean[] loaded = new boolean[1];
			final CountDownLatch loadLatch = new CountDownLatch(1);
			new Handler(Looper.getMainLooper()).post(new Runnable() {
				public void run() {
					try {
						WebView wv = new WebView(ctx);
						wvHolder[0] = wv;
						wv.setVisibility(android.view.View.INVISIBLE);
						wv.setWebViewClient(new WebViewClient() {
							public void onPageFinished(WebView view, String url) {
								loaded[0] = true;
								loadLatch.countDown();
							}
							public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
								loadLatch.countDown();
							}
						});
						wv.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
					} catch (Exception e) {
						android.util.Log.e("RepotPrint", "load err", e);
						loadLatch.countDown();
					}
				}
			});
			try { loadLatch.await(20, java.util.concurrent.TimeUnit.SECONDS); } catch (InterruptedException ignored) {}

			if (!loaded[0]) {
				cleanup(wvHolder[0]);
				fire(false, outputPath);
				return;
			}
			final WebView wv = wvHolder[0];

			final Picture[] picHolder = new Picture[1];
			final CountDownLatch capLatch = new CountDownLatch(1);
			new Handler(Looper.getMainLooper()).post(new Runnable() {
				public void run() {
					try {
						wv.measure(android.view.View.MeasureSpec.makeMeasureSpec(width, android.view.View.MeasureSpec.EXACTLY),
							android.view.View.MeasureSpec.makeMeasureSpec(height, android.view.View.MeasureSpec.AT_MOST));
						wv.layout(0, 0, wv.getMeasuredWidth(), wv.getMeasuredHeight());
						picHolder[0] = wv.capturePicture();
					} catch (Exception e) {
						android.util.Log.e("RepotPrint", "capture err", e);
					} finally {
						capLatch.countDown();
					}
				}
			});
			try { capLatch.await(20, java.util.concurrent.TimeUnit.SECONDS); } catch (InterruptedException ignored) {}
			Picture pic = picHolder[0];

			if (pic == null) { cleanup(wv); fire(false, outputPath); return; }

			try {
				File outFile = new File(outputPath);
				if (outFile.getParentFile() != null) outFile.getParentFile().mkdirs();
				PrintedPdfDocument doc = new PrintedPdfDocument(ctx, new PrintAttributes.Builder()
					.setMediaSize(PrintAttributes.MediaSize.ISO_A4)
					.setResolution(new PrintAttributes.Resolution("r", "r", 72, 72))
					.setMinMargins(PrintAttributes.Margins.NO_MARGINS)
					.build());
				int pageWidth = doc.getPageWidth();
				int pageHeight = doc.getPageHeight();
				int picW = pic.getWidth();
				int picH = pic.getHeight();
				if (picW <= 0 || picH <= 0) { cleanup(wv); doc.close(); fire(false, outputPath); return; }
				float scale = (float) pageWidth / (float) picW;
				int scaledH = (int) (picH * scale);
				int numPages = (scaledH + pageHeight - 1) / pageHeight;
				if (numPages < 1) numPages = 1;
				for (int i = 0; i < numPages; i++) {
					PrintedPdfDocument.Page page = doc.startPage(i);
					android.graphics.Canvas canvas = page.getCanvas();
					canvas.save();
					canvas.scale(scale, scale);
					float pageH = pageHeight / scale;
					canvas.clipRect(0, i * pageH, picW, (i + 1) * pageH);
					canvas.translate(0, -i * pageH);
					pic.draw(canvas);
					canvas.restore();
					doc.finishPage(page);
				}
				FileOutputStream fos = new FileOutputStream(outFile);
				doc.writeTo(fos);
				fos.close();
				doc.close();

				result[0] = outFile.length() > 0;
			} catch (Exception e) {
				android.util.Log.e("RepotPrint", "write err", e);
				result[0] = false;
			}
			cleanup(wv);
			fire(result[0], outputPath);
		}
	}).start();
}

private static anywheresoftware.b4a.BA getBA() {
	try {
		Class<?> c = Class.forName("b4a.example.reportb4aprint");
		java.lang.reflect.Field f = c.getField("processBA");
		anywheresoftware.b4a.BA ba = (anywheresoftware.b4a.BA) f.get(null);
		android.util.Log.i("RepotPrint", "module processBA=" + ba);
		if (ba != null) return ba;
	} catch (Exception e) {
		android.util.Log.e("RepotPrint", "module ba err", e);
	}
	try {
		Class<?> c = Class.forName("b4a.example.main");
		java.lang.reflect.Field f = c.getField("processBA");
		anywheresoftware.b4a.BA ba = (anywheresoftware.b4a.BA) f.get(null);
		android.util.Log.i("RepotPrint", "main processBA=" + ba);
		return ba;
	} catch (Exception e2) {
		android.util.Log.e("RepotPrint", "main ba err", e2);
		return null;
	}
}

private static void fire(boolean success, String path) {
	anywheresoftware.b4a.BA ba = getBA();

	if (ba != null) {
		try {
			ba.raiseEventFromUI(ba, "printcomplete", success, path);

		} catch (Exception e) {
			android.util.Log.e("RepotPrint", "raise err", e);
		}
		try {
			ba.raiseEventFromUI(ba, "reportb4aprint_printcomplete", success, path);

		} catch (Exception e) {
			android.util.Log.e("RepotPrint", "raise2 err", e);
		}
	}
}

private static void cleanup(final WebView wv) {
	if (wv == null) return;
	new Handler(Looper.getMainLooper()).post(new Runnable() {
		public void run() {
			try {
				if (wv.getParent() != null) {
					((android.view.ViewGroup) wv.getParent()).removeView(wv);
				}
				wv.destroy();
			} catch (Exception ignored) {}
		}
	});
}
#End If
#End If
#End If
