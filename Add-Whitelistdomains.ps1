Function Add-Whitelistdomains {
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]$domainlist,
        [Parameter(Mandatory = $true)]$Rulename
    )
    BEGIN {
        $list = Import-Csv -Path $domainlist -Delimiter ','
        $domains = @()
        foreach ($obj in $list){
            $dm = ($obj.Address -split '@')[1]
            $dm.trim()
            $domains += $dm
        }
    }
    PROCESS{
        IF (Get-Transportrule $rulename -EA SilentlyContinue){
            Write-Output "....... Updaten van bestaande transport regel $rulename .........."
            $Safedomains = Get-Transportrule $Rulename | Select-Object -ExpandProperty SenderDomainIs
            $Finallist = $Safedomains + $domains
            $Finallist = $Finallist | Select-Object -Unique | Sort-Object
            Set-Transportrule $Rulename -SenderDomainIs $Finallist
    }
    else{
        Write-Output "....... Maken van nieuwe transport regel $rulename .........."
        $domains = $domains | Sort-Object
        New-Transportrule $Rulename -SenderDomainIs $domains -SetSCL "-1"
    }
}
