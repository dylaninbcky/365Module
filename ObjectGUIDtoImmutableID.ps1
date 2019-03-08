Function GUIDto64{
    param($str);
    $g = new-object -TypeName System.Guid -ArgumentList $str;
    $b64 = [System.Convert]::ToBase64String($g.ToByteArray());
    return $b64;
}
Function ConvertADusers64{
    param (
        [parameter(Mandatory,Position=0,HelpMessage="Outputdirectory voor Csv")]
        $outputdirectory
    )
    $users = Get-Aduser -filter *
    $output = @()
    Foreach ($user in $users){
        $output += [pscustomobject]@{
            Email = $user.UserPrincipalname
            GUID = $user.ObjectGUID
            Immutable = (GUIDto64($user.ObjectGUID))
        }
    }
    $output | Out-File $outputdirectory
}

ConvertADusers64 -outputdirectory "C:\temp\immutableidtest.txt"
