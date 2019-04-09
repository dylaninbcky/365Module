Function Get-AzureMFAStatus {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][int]$MaxResults = 20000,
        [bool] $isLicensed = $true
    )
    BEGIN { Connect-MsolService -Credential (Get-Credential) }
    PROCESS { 
        $AdminUsers = Get-MsolRole | ForEach-Object { Get-MsolRoleMember -RoleObjectId $_.ObjectID } | Where-Object { $_.EmailAddress -ne $null } | Select-Object EmailAddress -Unique | Sort-Object EmailAddress
        $AllUsers = Get-MsolUser -MaxResults $MaxResults | Where-Object { $_.IsLicensed -eq $isLicensed } | Select-Object DisplayName, UserPrincipalName, `
        @{Name = 'isAdmin'; Expression = { if ($AdminUsers -match $_.UserPrincipalName) { Write-Output $true } else { Write-Output $false } } }, `
        @{Name = 'MFAEnabled'; Expression = { if ($_.StrongAuthenticationRequirements) { Write-Output $true } else { Write-Output $false } } }
     
     
        Write-Output $AllUsers | Sort-Object MFAEnabled, isAdmin
    }
}

Get-AzureMFAStatus 