function ConvertTo-Signature {
	[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true
                ,  Position = 0)]
        [string]
        $Key
        ,
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true)]
        [string]
        $Data
    )
    begin {
        $KeyString = [System.String]::Concat(($Key.Split("`n") | Where-Object { $_ -notmatch '^-----|^$' }))
        $KeyBytes = [Convert]::FromBase64String($KeyString)
        $ECDsa = [System.Security.Cryptography.ECDsa]::Create()
        $ECDsa.ImportPkcs8PrivateKey($KeyBytes, [ref]$null)
    }
    process {
        $DataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
        $SignedBytes = $ECDsa.SignData($DataBytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
        $Signature = [Convert]::ToBase64String($SignedBytes)
        $Signature -replace '\+', '-' -replace '/', '_' -replace '=+$', ''
    }
    end {}
}
