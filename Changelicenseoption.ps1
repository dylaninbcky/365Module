<#
Uiteraard kun je een Array maken van $plan, Bijv: "MCOSTANDARD","TEAMS1","LYNC4"
Hij staat standaard gefilterd op Onlineklas Attribute, namelijk NL. Deze kun je ook veranderen in * voor iedereen
Het is een wildcard comparison dus moet makkelijk werken voor vragen: Dylan@vwc.nl
#>


Function Changelicenseoption {
    param (
        $plan = "MCOSTANDARD",
        $license = "STANDARDWOFFPACK_STUDENT"
    )
    $MBX = Get-Msoluser -All | Where-Object {$_.UserPrincipalname -like "NL*"}
    $LicensesRemoved = 0
    ForEach ($M in $MBX) {
        Write-Host "Checking licenses for" $M.Userprincipalname
        $accountsku1 = (Get-MsolAccountSku).AccountSkuID -split ":"
        $tenantname = $accountsku1[0]
        if ((Get-MsolUser -UserPrincipalName $M.UserPrincipalName).Licenses.AccountSkuID -like "*$license") {
            $accountsku = "$tenantname" + ':' + "$license"
            $lo = New-MsolLicenseOptions -AccountSkuId $accountsku -DisabledPlans $plan
            Set-MsolUserLicense -UserPrincipalName $M.UserPrincipalName -LicenseOptions $lo
            Write-Host $license "is aangepast voor" $m.Userprincipalname -ForegroundColor Red
        }
        else {
            Write-Host "Licenties komen niet overeen met $license" -ForegroundColor Red
        }
    }
}

Changelicenseoption












