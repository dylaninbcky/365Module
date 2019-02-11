function ExchangeLogon {
    Read-Host -Prompt "Voer hier je Wachtwoord in" -AsSecureString | ConvertFrom-SecureString | Out-File $env:USERPROFILE\creds.txt
    $AdminNaam = Read-Host -Prompt "Voer hier je gebruikersnaam in"
    $Pass = Get-Content $env:USERPROFILE\creds.txt | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -Argumentlist $Adminnaam, $Pass
    Connect-Msolservice -Credential $Cred
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -Allowredirection
    Import-PSSession $Session
}
Function GetMailboxstats {
    param (
        [parameter(HelpMessage="Zet deze aan met -alleusers, voor het exporteren van de logondates voor alle users.")]
        [switch]$alleusers,
        [parameter(Position=0,HelpMessage="Als je niet kiest voor -alleusers zal je hier een user moeten kiezen")]
        [string]$user,
        [parameter(HelpMessage="Zet deze aan met -Csv voor een csv export, anders zul je een TXT bestand krijgen")]
        [switch]$csv
    )
    $date = Get-date -Format dd-MM
    if ($alleusers){
        $output = @()
        $users = Get-Mailbox -ResultSize Unlimited
        foreach ($user in $users){
            $stats = Get-MailboxStatistics -Identity $user.Identity | Select-Object DisplayName,ItemCount,LastLogonTime
            $output += $stats
        }
        if ($csv){
            $output | Export-Csv -Path "$env:USERPROFILE\$date.csv" -Force
            (Get-Content -Path "$env:USERPROFILE\$date.csv") -replace '"','' | Out-File -Path "$env:USERPROFILE\$date-Mailboxexport.csv"
            Remove-item -Path "$env:USERPROFILE\$date.csv" -Force
        }
        else{
            $output | Out-File -Path "$env:USERPROFILE\$date-Mailboxexport.txt"
        }
    }
    else {
        if ($user){
            $usercheck = Get-Mailbox
            if ($usercheck){
                Get-MailboxStatistics -identity $usercheck.Identity | Select-Object DisplayName,ItemCount,LastLogonTime
            }
            else{
                Write-Warning "User is niet gevonden"
            }
        }
        else{
            Write-Warning "Je hebt niet voor -alleusers gekozen, maar hebt ook geen -user opgegeven."
        }
    }
}




