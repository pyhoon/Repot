$file = "C:\Projects\Repot\source\Repot\ReportExpressionEvaluator.bas"
$content = Get-Content $file
# Line 303 (0-indexed: 302) is Catch, line 304 is d = 0, line 305 is End Try
# We need to add Log(LastException.Message) after Catch and before d = 0
# The catch block is:
#	Catch
#			d = 0
# We want:
#	Catch
#			Log(LastException.Message)
#			d = 0

# Find the line with just "Catch" and replace it with Catch + Log
for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i].Trim() -eq "Catch") {
        # Insert Log line after this line
        $content[$i] = "`t`tCatch"
        $content.Insert($i + 1, "`t`t`tLog(LastException.Message)")
        $i++ # Skip the inserted line
        # Now fix the d = 0 line - it should already have the right indent
        break
    }
}
Set-Content $file $content
Write-Host "Fixed Catch block in $file"