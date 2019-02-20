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
            Write-Host "License is aangepast" -ForegroundColor Red
        }
        else {
            Write-Host "Licenties komen niet overeen met $license" -ForegroundColor Red
        }
    }
}

Changelicenseoption












