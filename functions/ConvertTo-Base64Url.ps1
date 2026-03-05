function ConvertTo-Base64Url {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  Position = 0)]
        [string]
        $String
    )
    begin {}
    process {
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
        $Base64 = [Convert]::ToBase64String($Bytes)
        $Base64 -replace '\+', '-' -replace '/', '_' -replace '=+$', ''
    }
    end {}
}
