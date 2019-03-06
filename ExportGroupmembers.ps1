Function ExportGroupMembers {
    param (
        [parameter(Position=0, Mandatory=$false)]
        $outputdirectory
    )
    $outputfile = "GroepMembers.CSV"
    $arraymembers = @{}
    $credentials = Get-Credential
    #session
    try {
        $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credentials -Authentication Basic –AllowRedirection
        Import-PSSession $session
    }
    catch {
        Throw "Er kan geen verbinding worden gemaakt"
        Write-Warning $_
    }
    ## Preparing headers
    Out-File -FilePath "$outputdirectory\$outputfile" -InputObject "DisplayName,GroupEmail,MemberDisplayName, MemberEmail, MemberType" -Encoding UTF8
    ## Ophalen groepen
    $groups = Get-Distributiongroup -resultsize unlimited

    foreach ($group in $groups){
        write-host "Processing $($group.DisplayName)..."
        $groupmembers = Get-DistributionGroupMember -Identity $($group.PrimarySmtpAddress)
        Write-Host "Aantal Members gevonden: $($groupmembers.Count)"
        foreach ($member in $groupmembers){
            Out-File -FilePath "$outputdirectory\$OutputFile" -InputObject "$($group.DisplayName),$($group.PrimarySMTPAddress),$($member.DisplayName),$($member.PrimarySMTPAddress),$($member.RecipientType)" -Encoding UTF8 -append
            write-host "`t$($group.DisplayName),$($group.PrimarySMTPAddress),$($member.DisplayName),$($member.PrimarySMTPAddress),$($member.RecipientType)"
        }
    }
}

ExportGroupMembers -outputdirectory "C:\temp"