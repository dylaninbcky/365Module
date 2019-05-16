Function New-SharepointSite {
    [Cmdletbinding()]
    param (
        [parameter(Mandatory = $true, Helpmessage = "Titel voor site")]
        $Title,
        [parameter(Mandatory = $true, HelpMessage = "SiteURL.. bijvoorbeeld: dylanberghuis.sharepoint.com/sites/Demosite")]
        $SiteURL,
        [parameter(Mandatory = $true, HelpMessage = "Admin URL voor SPO-Connect PNP Provisioning")]
        $AdminURL,
        [parameter(HelpMessage = "DiffOwner, Voor een andere owner dan de gebruiker die dit aanmaakt, Zet deze switch aan je zult later gevraagd worden voor wie")]
        [switch]$DiffOwner,
        [parameter(HelpMessage = "StorageQuota, default staat deze op 1000. Als je deze wilt aanpassen kan dat met -StorageQuota 500")]
        $StorageQuota = 1000,
        [parameter(HelpMessage = "RecourceQuota, default staat deze op 50. Als je deze wilt aanpassen kan dat met -ResourceQuota 500")]
        $ResourceQuota = 50
    )
    BEGIN {
        $CREDS = Get-Credential -Message "Global Admin of Sharepoint Admin creds SVP"
        try {
            Connect-SpoService -Url $AdminURL -Credential $CREDS
        }
        catch {
            Throw "Kon geen verbinding maken met site."
        }
    }
    PROCESS{
        if ($DiffOwner){
            $owner = Read-host -Prompt "Wie kies je als owner? Volledig emailadres SVP"
        }
        else {
            $owner = $CREDS.UserName
        }
        if (!(Get-SpoSite | Where-Object {$_.url -eq $SiteURL}) -and !(Get-SpoDeletedSite | Where-Object {$_.Url -eq $SiteURL})){
            Write-Host "Passed Checks, Kies nu de Template."
            Get-SpoWebTemplate | Select-Object Title,Name
            $template = Read-Host "Welke template wil je? Input de Name value"
            $Splatting = @{
                Url = $SiteURL
                Title = $Title
                Owner = $owner
                StorageQuota = $StorageQuota
                ResourceQuota = $ResourceQuota
                Nowait = Nowait
                Template = $template
            }
            Write-Host "Splatting Completed, $Title word nu gemaakt!" -ForegroundColor Green
            try {
            New-Sposite $Splatting
            }
            catch {
                Throw "Site Kon niet gemaakt worden...."
            }
            
        }
        else{
            Throw "site bestaat al. Check ook de Recycle Bin!"
        }

    }
}
