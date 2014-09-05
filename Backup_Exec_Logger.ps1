# ------------------------------------------------------------------------
# NAME: Backup_Exec_Logger.ps1
# AUTHOR: Cody Eding
# DATE: 6/6/2014
#
# COMMENTS: Invokes Backup Exec 2014 cmdlets to determine job status for
# any jobs occurring in the past 24 hours and log to file on server. If
# job status is anything but "Successful," fire off an email with the log
# file attached.
#
# ------------------------------------------------------------------------

# Edit these variables to suit your environment ##############

$To = "alerts@domain.com"
$From = "$env:hostname <noreply@domain.com>"
$SmtpServer = "smtp.domain.net"
$LogPath = "\\FILESERVER\Backup Exec Logs"

##############################################################

Import-Module "$env:programfiles\Symantec\Backup Exec\Modules\BEMCLI"

$JobHistory = Get-BEJobHistory -FromStartTime (Get-Date).AddHours(-24) | Select JobName,JobStatus,EndTime,ElapsedTime

$Now = Get-Date
$Day = $Now.Day
$Month = $Now.Month
$Year = $Now.Year
$LogFile = "$LogPath\$Year\$Month\$Day.html"

# Uses Pure CSS framework for some eye candy.
New-Item $LogFile -type file -force -value "<!DOCTYPE html><html><head><title>Backup Exec 2012 Report: Jobs Ending $Now</title></head><link rel="stylesheet" href='http://yui.yahooapis.com/pure/0.5.0/pure-min.css'><body><table class='pure-table pure-table-horizontal'><thead><th>Job Name</th><th>Status</th><th>End Time</th><th>Elapsed Time</th></thead>" | Out-Null

$JobHistory | Foreach-Object {
	$Job = $_.JobName
	$Status = $_.JobStatus
	$EndTime = $_.EndTime
	$ElapsedTime = $_.ElapsedTime
	If ( $_.JobStatus -ne "Succeeded" ) {
		$Alert = 1
		Add-Content $LogFile "<tr><td>$Job</td><td style='background-color: yellow;'>$Status</td><td>$EndTime</td><td>$ElapsedTime</td></tr>"
	} Else {
		Add-Content $LogFile "<tr><td>$Job</td><td style='background-color: green;'>$Status</td><td>$EndTime</td><td>$ElapsedTime</td></tr>"
	}
}

Add-Content $LogFile "</table></body></html>"

If ( $Alert -eq 1 ) {
	Send-MailMessage -BodyAsHtml -SmtpServer $SmtpServer -To $To -From $From -Subject "$Now Backup Exec 2014 Job Notification" -Body "One or more Backup Exec jobs did not finish with 'Succeeded' status. Please see the attached log file for more details." -Attachments $LogFile
}

