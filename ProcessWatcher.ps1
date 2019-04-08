param (
    [Parameter(Mandatory=$true)]$ID,
    [Parameter(Mandatory=$false)][string]$Description = "No process description given",
    [Parameter(Mandatory=$false)][string]$recipient   = "xXxXx@xXxXxX.com",
    [Parameter(Mandatory=$false)][string]$SendAs      = "processwatcher@xXxXx.com",
    [Parameter(Mandatory=$false)][string]$smtpServer  = "SmTp.xXxXxX.com"
    )

function Log {
    Param (
        [Parameter(Mandatory=$true,ValueFromRemainingArguments=$true)] [string[]]$message = "Unspecified Input",
        [Parameter(Mandatory=$false)] [Switch]$console = $false
    )
    if($PSBoundParameters.ContainsKey('console')) {
        Write-host $message -ForegroundColor Yellow
    }
    $logfile = $logfilepath+$logFileName
    $logdate = get-date -Format yyyy-MM-dd-HH:mm:ss
    $logheader = "["+$logdate+"]"
    $logline = $logheader + $message
    if (!(Test-path $logfile)) {
        new-item -path $logfilepath -name $logFileName -ItemType "File" -Value "$logHeader===== New Log File Created =====`r`n"|out-null
        add-content $logfile " "
        add-content $logfile $logline
    }
    add-content $logfile $logline
}
### BEGIN MAIN CODE ###

$error.clear()
### SET LOG FILE PATH & FILENAME ##
$logFilePath = "c:\temp\"
$logFileName = "ProcessWatcher.log"
### Nothing is logged using the -console parameter, because this script will always be called by some other script and never seen. 
Log "ProcessWatcher Started."

if (!($ID)) {
    Log "NO Process ID Given! Exiting."
    send-mailmessage -to $recipient -from $sendAs -subject "No Process ID Given!" -body "ProcessWatcher launched, but was not given a process ID to watch. Exited." -SmtpServer $smtpServer
    exit
}

$processToMonitor = get-process -id $ID
if (!($processToMonitor)) {
    Log "NO Process with ID $ID Found! Exiting."
    $subject = "Error - No Process ID $ID Found"
    $body = "A trigger was set to monitor when process ID $ID was finished, but no process of that ID was found."
    send-mailmessage -to $recipient -from $SendAs -subject $subject -body $body -SmtpServer $smtpServer
}

Else {
    $processName = $(get-process -id $ID).Name
    Log "Process ID $ID Found. Name: $processName"
    Log "Waiting for it to finish...."
    Wait-Process -ID $ID
    
    ### DO POST-JOB ITEMS HERE ###

    $subject = "** JOB COMPLETE ** Process ID $ID, $processName ($description) has terminated"
    $body = "Process ID $id, $processName ($description) has finished executing at $(get-date)."
    Log "Process ID $ID Finished. Sending E-mail"
    Log "Subj" $subject
    Log "Body" $body

    send-mailmessage -to $recipient -from $SendAs -subject $subject -body $body -SmtpServer $smtpServer
}
if ($error) {Log $Error}

###############################