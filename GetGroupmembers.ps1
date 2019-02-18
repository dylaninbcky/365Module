Function GetGroupmembers {
    param (
        [parameter(Mandatory,HelpMessage="Voer hier je outputdirectory voor CSV file in")]
        [string]$outputpath
    )
    $groepen = Get-UnifiedGroup -ResultSize Unlimited
    $groepscsv = @()
    
    foreach ($groep in $groepen){
        Write-Host "Ophalen van gebruikers ff geduld" -ForegroundColor Green
        $leden = Get-UnifiedGroupLinks -identity $groep.Identity -LinkType Member -ResultSize Unlimited
        $ledenmail = @()
        foreach ($lid in $leden){
            $ledenmail+=$lid.PrimarySMTPAddress
        }
        $eigenaren = Get-UnifiedGroupLinks -Identity $groep.Identity -LinkType Owner -ResultSize Unlimited
        $eigenaarmail = @()
        foreach ($eigenaar in $eigenaren){
            $eigenaarmail+=$eigenaar.PrimarySMTPAddress
        }
        # Create CSV file line
        $GroupsRow =   [pscustomobject]@{
            GroupMail = $groep.PrimarySmtpAddress
            GroupIdentity = $groep.Identity
            GroupDisplayName = $Groep.DisplayName
            Ledenmail = $ledenmail -join "`n"
            Ownermail = $eigenaarmail -join "`n"
        }
        $groepscsv += $GroupsRow
    }
    Write-Host "Het bestand word geexporteerd" -ForegroundColor Green
    $groepscsv | Export-Csv -NoTypeInformation -Path $outputpath
}
