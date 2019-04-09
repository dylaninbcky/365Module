function ExchangeLogon {
    Read-Host -Prompt "Voer hier je Wachtwoord in" -AsSecureString | ConvertFrom-SecureString | Out-File $env:USERPROFILE\creds.txt
    $AdminNaam = Read-Host -Prompt "Voer hier je gebruikersnaam in"
    $Pass = Get-Content $env:USERPROFILE\creds.txt | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -Argumentlist $Adminnaam, $Pass
    Connect-Msolservice -Credential $Cred
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -Allowredirection
    Import-PSSession $Session
}
