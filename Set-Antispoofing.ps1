<#
Maakt een transport rule aan based op alle displaynames, checkt of incoming mail daarop lijk, en voegt html toe accordingly
#>

##HTML vanaf /r/powershell
$ruleName = "External Senders with matching Display Names"
$ruleHtml = "<table class=MsoNormalTable border=0 cellspacing=0 cellpadding=0 align=left width=`"100%`" style='width:100.0%;mso-cellspacing:0cm;mso-yfti-tbllook:1184; mso-table-lspace:2.25pt;mso-table-rspace:2.25pt;mso-table-anchor-vertical:paragraph;mso-table-anchor-horizontal:column;mso-table-left:left;mso-padding-alt:0cm 0cm 0cm 0cm'>  <tr style='mso-yfti-irow:0;mso-yfti-firstrow:yes;mso-yfti-lastrow:yes'><td style='background:#910A19;padding:5.25pt 1.5pt 5.25pt 1.5pt'></td><td width=`"100%`" style='width:100.0%;background:#FDF2F4;padding:5.25pt 3.75pt 5.25pt 11.25pt; word-wrap:break-word' cellpadding=`"7px 5px 7px 15px`" color=`"#212121`"><div><p class=MsoNormal style='mso-element:frame;mso-element-frame-hspace:2.25pt; mso-element-wrap:around;mso-element-anchor-vertical:paragraph;mso-element-anchor-horizontal: column;mso-height-rule:exactly'><span style='font-size:9.0pt;font-family: `"Segoe UI`",sans-serif;mso-fareast-font-family:`"Times New Roman`";color:#212121'>Dit bericht is verstuurd door iemand buiten de organisatie met dezelfde weergavenaam. Vertrouw dit bericht niet. <o:p></o:p></span></p></div></td></tr></table>"
## Connecting
Read-Host -Prompt "Voer hier je Wachtwoord in" -AsSecureString | ConvertFrom-SecureString | Out-File $env:USERPROFILE\creds.txt
$AdminNaam = Read-Host -Prompt "Voer hier je gebruikersnaam in"
$Pass = Get-Content $env:USERPROFILE\creds.txt | ConvertTo-SecureString
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -Argumentlist $Adminnaam, $Pass
Connect-Msolservice -Credential $Cred
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Cred -Authentication Basic -Allowredirection
Import-PSSession $Session
#if connection -eq true
if ($session) {
    $rule = Get-TransportRule | Where-Object {$_.Identity -contains $ruleName}
    $displayNames = (Get-Mailbox -ResultSize Unlimited).DisplayName
    #if regel -noteq true
    if (!$rule) {
        Write-Host "Regel niet gevonden, Bezig met toevoegen.." -ForegroundColor Green
        New-TransportRule -Name $ruleName -Priority 0 -FromScope "NotInOrganization" -ApplyHtmlDisclaimerLocation "Prepend" `
            -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -ApplyHtmlDisclaimerText $ruleHtml
    }
    else {
        Write-Host "Regel gevonden, word aangepast" -ForegroundColor Green
        Set-TransportRule -Identity $ruleName -Priority 0 -FromScope "NotInOrganization" -ApplyHtmlDisclaimerLocation "Prepend" `
            -HeaderMatchesMessageHeader From -HeaderMatchesPatterns $displayNames -ApplyHtmlDisclaimerText $ruleHtml
    }
}
else {
    Write-Warning  "er kan geen verbinding worden gemaakt" 
}
