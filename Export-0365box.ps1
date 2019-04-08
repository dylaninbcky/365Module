## Function Export-O365Inbox

## This function calls another external powershell script (ProcessWatcher) AND
## the office data downloader which MUST exist in the path given.
## This function will open a channel to the Azure Security & Compliance session.
## Then it creates a "Search" consisting of the user's entire inbox & archive.
## It then begins the process of building an Export of that entire search.
## We grab the download URL and the secret "SASkey" from the job "Result" field;
## This involves some crazy parsing.

## Then, locally, 2 processes get spawned: 1, the download launcher, and 2, 
## a process which is a completely separate PS script called "ProcessWatcher".
## Process watcher gets passed the Process ID of the downloader. When the downloader
## is finished, ProcessWatcher sends an e-mail to somebody, informing them that the 
## download is complete.

## This is possible because the downloader can be started far before the indexing
## is actually complete; it will sit there, running for hours, checking O365 occasionally,
## then begin the download once the indexing is complete. Most I've seen it go is
## 1.5 days. Yes, days. (90 gig inbox + archive)

## These processes, once kicked off, free up this script to continue running.
## The download can take hours or days.

## If the S&C Search is already initiated, this function will notice and will NOT try to
## start another one-- AS LONG AS the naming convention LASTNAME_FIRSTNAME_INBOX is used!!
## So, you CAN go to O365 and initiate the search & begin the indexing as long as the name
## matches this, it will work.

## The downloader, called microsoft.office.client.discovery.unifiedexporttool.exe,
## is an app that gets dynamically downloaded & updated via IE/Edge when you click on the
## download link from the web page of O365 S&C area. If you do not have this tool installed already,
## you must initiate a manual download first, to actually download & install the application.
## After it gets installed, you have to
## Find this (in %appdata%) and copy it to the path indicated... OR, in the future, I need to 
## figure out in the registry how to locate where it's located; i.e. how does IE know where it
## is to launch it?

## A good way to find the EXE is to kick off a download then use task mgr to find the path.
## Also, MS may decide to upgrade this app at any point, upon which this script may stop working
## and force us to kick off another manual download and re-install the latest version of
## the downloader. This has happened once so far in the few months that I've been using this
## method.

Function Export-O365Inbox ($user, $msCred) {
    # Take in the ad user object to be processed, and also the creds for o365 admin
    $SearchName = $user.Surname+"_"+$user.GivenName+"_INBOX"
  
    $dateString = get-date -Format yyyy-MM-dd-HH-mm
    
    $userMail = $user.mail
    $exportlocation = $inboxDownloadLocation #From The Global Vars set in main code. enter the path to your export here !NO TRAILING BACKSLASH!
    $exportexe = "C:\o365\microsoft.office.client.discovery.unifiedexporttool.exe" #path to your microsoft.office.client.discovery.unifiedexporttool.exe file. Usually found somewhere in %LOCALAPPDATA%\Apps\2.0\
    if (!(Test-Path $exportexe)) {Log "ERROR! Downloader Not found!" -console}

    # Connect to security & Compliance
    $Session2search = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $msCred -Authentication Basic -AllowRedirection
    Import-PSSession $Session2search -AllowClobber -DisableNameChecking

    if ($(get-complianceSearch $searchname -errorAction silentlyContinue)) {
       
    }
    else {
        
        New-ComplianceSearch -ExchangeLocation $user.mail -Name $SearchName -Description "User offboarding"
       
        Start-ComplianceSearch $SearchName
        # You'll see red on the screen if you don't wait a bit for O365 to actually create the search.
        # start-sleep -s 20
        do
        {
            Start-Sleep -s 10
            $complianceSearch = Get-ComplianceSearch $SearchName
            
        # Added the -or to check if it actually EXISTS yet.
        } while (($complianceSearch.Status -ne 'Completed') -or (!(get-complianceSearch $searchName)))
    }
    # Microsoft automatically adds the _Export affix to all exports, so we use that name to run our query.
    $JobName = $SearchName+"_Export"
    if (get-complianceSearchAction -identity $jobname -erroraction SilentlyContinue) {
        
    }
    else {
        # Create Compliance Search in exportable format. GIVE it the SEARCH name not the JOB name.
        
        New-ComplianceSearchAction -SearchName $SearchName -EnableDedupe $true -Export -Format FxStream -ArchiveFormat PerUserPST
        # Microsoft automatically adds the "_Export" to create the Job name.
    }


     do {

        # THERE IS A CHANCE THAT THE SASKEY WILL NOT POPULATE RIGHT AWAY.
        # If so, then the huge string attribute, "Results", will not yield the expected
        # results when attempting to parse the download URL and the SAS key.
        # THUS THIS $saskey MAY BE CORRUPT. HOPEFULLY THIS START-SLEEP FIXES THAT..
        # Not the most robust method; we could 'do until index.status -eq "completed"'.
        # I really hate doing "Wait and hope it's ready by the time we're done waiting" code..
        # Therefore, this "Do Until" *Should* ensure that the URL and the key are there.
        # It has not blown up yet... ;)

        # Check every 10 seconds that the search has been CREATED, not that it's DONE.
        # It just needs to be CREATED, then $index.status will equal True.
        Start-Sleep -s 10
        # If I don't have "-IncludeCredential there, I get a message in 'results' that says, SAS token: <specify -includecredential parameter to show the SAS token.
        $index = Get-ComplianceSearchAction -Identity $jobname -includeCredential
        # THIS METHOD OF EXTRACTING THE DETAILS MAY WORK BETTER IN THE FUTURE.
        # I DID grab some of this code from somebody else online but theirs frankly did not work.
        # It did, however, supply some key syntax that was needed and provided the framework for this
        # working copy.
        #$exportdetails = Get-ComplianceSearchAction -Identity $exportname -IncludeCredential -Details | select -ExpandProperty Results | ConvertFrom-String -TemplateContent $exporttemplate
        #$exportdetails
        #$exportcontainerurl = $exportdetails.ContainerURL
        #$exportsastoken = $exportdetails.SASToken
        $index
        $y=$index.Results.split(";")
        $url = $y[0].trimStart("Container url: ")
        $sasKey = $y[1].trimStart(" SAS token: ")
        $estSize = $y[18]
        $progress = $y[22]
        # These dont appear to be populated yet by the time we try to read them.
        if ($estSize) {Log "Estimated Size:" $estSize -console}
        else {Log "No Estimated Size" -console}

    } until ($index.Status -eq 'Completed')
    # Couldn't ever get this to work for some reason. Don't really care. Someday maybe I'll care enough to fix.
    

    # Download the exported files from Office 365
    
    $traceFileName = "c:\temp\"+$jobname+"-"+$dateString+".log"
    $errorFilename = "c:\temp\exportInbox-errorlog"+$dateString+".txt"
  
    $arguments = "-name `"$jobName`" -source `"$url`" -key `"$sasKey`" -dest `"$exportlocation`" -trace $traceFileName"
    # WindowStyle does not appear to work for this exe. But I left it there in case in the future it does.
    
    $downLoadProcess = Start-Process -FilePath "$exportexe" -ArgumentList $arguments -Windowstyle Normal -RedirectStandardError $errorfilename -PassThru
    $ProcessID = $downloadProcess.Id
   

    # Here we spawn a 2nd 'process watcher' process that waits until the downloader is finished (Terminated).
    # Then it'll kick off an e-mail saying the download is complete.
    $processDescription = "Email Download Job for $jobName"
    $procWatcher = Start-Process powershell.exe -ArgumentList "ProcessWatcher.ps1 -description '$processDescription' -id $ProcessID" -RedirectStandardError $errorfilename -WindowStyle Hidden -PassThru
  

    # That's it. We've spawned 2 external processes: One is the downloader, which will wait until the indexing is complete and then begin the download.
    # Second is the ProcessWatcher, which will e-mail us when the downloader completes and exits.
    Remove-psSession $session2search
}


$inboxDownloadLocation = "C:\Temp" # NO Trailing Slash!

$msCred = Get-Credential
Export-O365Inbox $thisuser $msCred