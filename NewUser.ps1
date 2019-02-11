Function New365User {
    <#
    Gebruik het script zo: New365User -Fullname 'Dylan Gerardus Hendrik' -upn "Dylangerardus@hogevlieger.nl" -Type "Leraar"
    
    Je hebt keuzes uit de volgende types, en de licenties werken zo. Dat ze bij de eerste hit de licentie mappen
    -Leraar (Eerst A1, dan E3, Dan E3 plus)
    -Leerling (A1, E3, en dan E3 Plus)
    -Bedrijf (Exchange Online, Pro plus, Business premium)
    
    Als je -Meerdereusers kiest, zul je ook een pad van een csv op moeten geven.
    De CSV zal de volgende headers moeten bevatten: UserPrincipalname, Firstname, Lastname, Displayname, 
    
    #>
    
    param (
        [parameter(Position = 0, HelpMessage = "Gebruik: -Fullname 'Dylan Berghuis'")]
        [string]$Fullname,
        [parameter(Position = 1, HelpMessage = "Voer hier het gewenste mail adres in + domain")]
        [string]$upn,
        [parameter(HelpMessage = "Als je -Meerdereusers toevoegd aan de New365User command, zul je een pad moeten opgeven met een csv file. Deze moet kommagescheiden zijn")]
        [switch]$Meerdereusers,
        [parameter(Mandatory, HelpMessage = "Kies hier uit Bedrijf,Leraar of Leerling")]
        [string]$Type
    )
    ##ARRAY FOR LICENSES
    $licenseleraar = @(
        "STANDARDWOFFPACK_FACULTY"
        "ENTERPRISEPACK_FACULTY"
        "ENTERPRISEPACKPLUS_FACULTY"
    )
    $licenseleerling = @(
        "STANDARDWOFFPACK_STUDENT"
        "ENTERPRISEPACK_STUDENT"
        "ENTERPRISEPACKPLUS_STUDENT"
    )
    $licensebedrijf = @(
        "EXCHANGESTANDARD"
        "O365_BUSINESS_PREMIUM"
        "OFFICESUBSCRIPTION"
    )
    #input .net class voor pw
    Add-Type -AssemblyName Sytem.Web
    $creds = Get-Credential
    ##connection
    try {
        Connect-MsolService -Credential $creds
    }
    Catch {
        Write-Warning $_
        Exit
    }
    if ($Meerdereusers) {
        $pad = Read-Host "Voer hier het pad in van je CSV"
        if (Test-Path $pad) {
            Write-Warning "Het pad is juist, bezig met doorgaan....."
        }
        else {
            Write-Warning "Het pad: $pad kan niet worden gevonden"
        }
        $users = Import-Csv -Path $pad -Delimiter ","
        foreach ($user in $users) {
            $pw = [System.Web.Security.Membership]::GeneratePassword(10, 1)
            New-Msoluser -UserPrincipalName $user.UserPrincipalName -DisplayName $user.DisplayName -FirstName $user.Firstname -LastName $user.Lastname -Password $pw -UsageLocation 'NL'
            if ($Type -eq "Bedrijf") {
                $MsolAccountSku = Get-MsolAccountSku
                Foreach ($license in $licensebedrijf) {
                    $MatchingSku = $null
                    $MatchingSku = $MsolAccountSku | Where-Object {$_.AccountSkuID -match "$($License)$"}
                    If ($null -ne $MatchingSku) {
                        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses $MatchingSku.AccountSkuID 
                        break
                    }
                }
            }
            elseif ($Type -eq "Leraar") {
                $MsolAccountSku = Get-MsolAccountSku
                Foreach ($license in $licenseleraar) {
                    $MatchingSku = $null
                    $MatchingSku = $MsolAccountSku | Where-Object {$_.AccountSkuID -match "$($License)$"}
                    If ($null -ne $MatchingSku) {
                        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses $MatchingSku.AccountSkuID 
                        break
                    }
                }
            }
            elseif ($Type -eq "Leerling") {
                $MsolAccountSku = Get-MsolAccountSku
                Foreach ($license in $licenseleerling) {
                    $MatchingSku = $null
                    $MatchingSku = $MsolAccountSku | Where-Object {$_.AccountSkuID -match "$($License)$"}
                    If ($null -ne $MatchingSku) {
                        Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -AddLicenses $MatchingSku.AccountSkuID 
                        break
                    }
                }
            }
        }
    }
    #SPLITBLOCK voor voornaam en achternaam
    If ($Fullname) {
        $namesplit = $Fullname.Split()
        $firstname = $namesplit[0]
        $lastname = $namesplit[$namesplit.Count - 1]
        if ($upn) {
            $check = Get-Msoluser | Where-Object {$_.UserPrincipalName -like "$upn*"}
            if (!$check) {
                if ($Type -eq "Bedrijf") {
                    $pw = [System.Web.Security.Membership]::GeneratePassword(10, 1)
                    New-MsolUser -UserPrincipalName $upn -FirstName $firstname -LastName $lastname -Password $pw -UsageLocation 'NL'
                    Write-Warning "Wachten tot user gecreate is, zodat de license kan worden gemapt (Dit duurt 2 seconden)"
                    Start-Sleep -Seconds 5
                    $MsolAccountSku = Get-MsolAccountSku
                    Foreach ($license in $licensebedrijf) {
                        $MatchingSku = $null
                        $MatchingSku = $MsolAccountSku | Where-Object {$_.AccountSkuID -match "$($License)$"}
                        If ($null -ne $MatchingSku) {
                            Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $MatchingSku.AccountSkuID
                            Write-Warning "De License is gemapt, je zult zo het wachtwoord zien en False bij islicensed. dat is omdat het niet snel genoeg laad.."
                            break
                        }
                    }
                }
                elseif ($type -eq "Leerling") {
                    $pw = [System.Web.Security.Membership]::GeneratePassword(10, 1)
                    New-MsolUser -UserPrincipalName $upn -FirstName $firstname -LastName $lastname -DisplayName $Fullname -Password $pw -UsageLocation 'NL'
                    Write-Warning "Wachten tot user gecreate is, zodat de license kan worden gemapt (Dit duurt 2 seconden)"
                    Start-Sleep -Seconds 5
                    $MsolAccountSku = Get-MsolAccountSku
                    Foreach ($license in $licenseleerling) {
                        $MatchingSku = $null
                        $MatchingSku = $MsolAccountSku | Where-Object {$_.AccountSkuID -match "$($License)$"}
                        If ($null -ne $MatchingSku) {
                            Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $MatchingSku.AccountSkuID 
                            Write-Warning "De License is gemapt, je zult zo het wachtwoord zien en False bij islicensed. dat is omdat het niet snel genoeg laad.."
                            break
                        }
                    }
                }
                elseif ($type -eq "Leraar") {
                    $pw = [System.Web.Security.Membership]::GeneratePassword(10, 1)
                    New-MsolUser -UserPrincipalName $upn -FirstName $firstname -LastName $lastname -DisplayName $Fullname -Password $pw -UsageLocation 'NL'
                    Write-Warning "Wachten tot user gecreate is, zodat de license kan worden gemapt (Dit duurt 2 seconden)"
                    $MsolAccountSku = Get-MsolAccountSku
                    Foreach ($license in $licenseleraar) {
                        $MatchingSku = $null
                        $MatchingSku = $MsolAccountSku | Where-Object {$_.AccountSkuID -match "$($License)$"}
                        If ($null -ne $MatchingSku) {
                            Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $MatchingSku.AccountSkuID
                            Write-Warning "De License is gemapt, je zult zo het wachtwoord zien en False bij islicensed. dat is omdat het niet snel genoeg laad.."
                            break
                        }
                    }
                }
            }
            else {
                Write-Warning "De user bestaat al"
            }
        }
        else {
            Write-Warning "Er is geen UPN ingevoerd, call het script met -UPN"
        }
    }
    else {
        Write-Warning "Er is geen Naam ingevoerd, call het script met -Fullname"
    }
}


New365User -Fullname "CarloTesting Test" -upn 'CarloTesting@triangelrouveen.onmicrosoft.com' -Type "Leraar" 
