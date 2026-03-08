$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$ParentDir = ([System.IO.DirectoryInfo]$PSScriptRoot).Parent
$Data = Import-Clixml -Path (Join-Path -Path $ParentDir -ChildPath '.claimsData.xml')

# JWT
$Now = [System.DateTimeOffset]::FromUnixTimeSeconds(1772930738) #[System.DateTimeOffset]::Now
$JwtId = 'cdfb3900-fc70-45ff-a05b-d546416f00e1' #[guid]::NewGuid().Guid
$TimeToLive = (New-TimeSpan -Hours 1)
$JwtHeader = @{
    kid = $Data.KeyId
    alg = 'ES256'
} | ConvertTo-Json -Compress
$Bytes = [System.Text.Encoding]::UTF8.GetBytes(([string]$JwtHeader))
$Base64 = [Convert]::ToBase64String($Bytes)
$EncHeader = $Base64 -replace '\+', '-' -replace '/', '_' -replace '=+$', ''
$JwtPayload = @{
    aud = $Data.TokenUrl
    iss = $Data.TeamId
    sub = $Data.ClientId
    iat = $Now.ToUnixTimeSeconds()
    #exp = $Now.AddMinutes(5).ToUnixTimeSeconds()
    exp = $Now.AddSeconds($TimeToLive.TotalSeconds).ToUnixTimeSeconds()
    jti = $JwtId
} | ConvertTo-Json -Compress
$Bytes = [System.Text.Encoding]::UTF8.GetBytes(([string]$JwtPayload))
$Base64 = [Convert]::ToBase64String($Bytes)
$EncPayload = $Base64 -replace '\+', '-' -replace '/', '_' -replace '=+$', ''
$SigningInput = [System.String]::Concat($EncHeader, '.', $EncPayload)

# Signature
$KeyString = [System.String]::Concat((($Data.PrivateKey | ConvertFrom-SecureString -AsPlainText).Split("`n") | Where-Object { $_ -notmatch '^-----|^$' }))
$KeyBytes = [Convert]::FromBase64String($KeyString)
$ECDsa = [System.Security.Cryptography.ECDsa]::Create()
$ECDsa.ImportPkcs8PrivateKey($KeyBytes, [ref]$null)
$JwsPayload = [System.Text.Encoding]::UTF8.GetBytes($SigningInput)
$SignedJwsPayload = $ECDsa.SignData($JwsPayload, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$SignedBase64 = [Convert]::ToBase64String($SignedJwsPayload)
$JwsSignature = $SignedBase64 -replace '\+', '-' -replace '/', '_' -replace '=+$', ''

# JWS
$JwsCompactSerialization = [System.String]::Concat($SigningInput, '.', $JwsSignature)
Write-Host $JwsCompactSerialization -ForegroundColor Green
Write-Debug -Message "$($MyInvocation.MyCommand.Name): `$JwsCompactSerialization: [$($JwsCompactSerialization.Split('.')[0..1].ForEach({$_|ConvertFrom-Base64Url}) -join ',')]"
# Access Token
$Headers = @{
    'Host'         = 'account.apple.com'
    'Content-Type' = 'application/x-www-form-urlencoded'
}
$Attributes = @{
    Uri     = $Data.TokenUrl
    Method  = 'POST'
    Headers = $Headers
}

$QueryData = @{
    grant_type            = 'client_credentials'
    scope                 = 'business.api'
    client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
    client_assertion      = $JwsCompactSerialization
    client_id             = $Data.ClientId
}
$Query = @()
foreach ($k in $QueryData.Keys) {
    $Query += "$($k)=$([uri]::EscapeDataString($QueryData[$k]))"
}
if ($Query.Count -gt 0) { $Attributes.Uri = "$($Data.TokenUrl)?$($Query -join '&')" }

try {
    $Response = Invoke-RestMethod @Attributes
    $Response | ConvertTo-Json -Compress
}
catch {
    throw $_
}
break
$oDev = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Response.access_token)"} -Method Get -Uri 'https://api-business.apple.com/v1/orgDevices'