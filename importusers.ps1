Function ImportGroupusersCSV {
    param (
        [parameter(Mandatory, HelpMessage = "CSV input file")]
        $csvfile
    )
    try {
        $csv = import-csv -Path $csvfile
    }
    catch {
        Throw $_
    }
    ## makenn van groepen
    $groepen = $csv.Displayname | Select-Object -Unique
    Foreach ($groep in $groepen) {
        if ($groep.Displayname -notlike "Groep*") {
            try {
                New-ADGroup -DisplayName $groep -GroupCategory Distribution -GroupScope Global -Name $groep -Path "OU=Overige,OU=edu,DC=edu,DC=local"
                Write-Verbose "Created $groep"
            }
            catch {
                Throw $_.Exception.Response
            }
        }
    }
    ## erin stoppen van users
    foreach ($user in $csv) {
        $grp = Get-ADGroup -Identity $user.Displayname
        if ($grp) {
            $usr = Get-ADUser -filter * | Where-Object {$_.Userprincipalname -eq $user.MemberEmail}
            Write-Verbose "performing on $($user.Memberemail)"
            $grp | Add-ADGroupMember -Members $usr -WhatIf
        }
        else {
            Write-Warning "Groep kan niet worden gevonden, terminating script"
            exit
        }
    }
}

ImportGroupusersCSV -csvfile "C:\temp\DistributionGroupMembers.CSV" -Verbose

