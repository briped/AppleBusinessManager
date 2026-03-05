. ./functions.ps1

$Data = Import-Clixml -Path '.apiData.xml'

# Prepare the JSON Web Token Header
$JwtHeader = @{
    kid = $Data.KeyId | ConvertFrom-SecureString -AsPlainText #Key ID.
    alg = $Data.TokenAlgorithm # Algorithm. ES256
    typ = $Data.TokenType # JWT
} | ConvertTo-Json -Compress

# Parepare the JSON Web Token Claims Set.
$JwtClaimsSet = @{
    aud = $Data.TokenUrl # Audience. https://account.apple.com/auth/oauth2/v2/token
    iss = $Data.TeamId | ConvertFrom-SecureString -AsPlainText # Issuer.
    sub = $Data.ClientId | ConvertFrom-SecureString -AsPlainText # Subject
    iat = [System.DateTimeOffset]::Now.ToUnixTimeSeconds() # The current time in UnixTimeSeconds format. IssuedAt. When the claim was issued.
    nbf = [System.DateTimeOffset]::Now.ToUnixTimeSeconds() # The current time in UnixTimeSeconds format. NotBefore. When the token will become valie.
    exp = [System.DateTimeOffset]::Now.AddHours(1).ToUnixTimeSeconds() # Future time in UnixTimeSeconds format. Expire. When the token expires/becomes invalid.
    jti = [guid]::NewGuid().Guid # Globally/Universally Unique IDentifier. JWT ID
} | ConvertTo-Json -Compress

# Encode the JwtHeader and the JwtClaimsSet
$EncodedJwtHeader = $JwtHeader | ConvertTo-Base64Url
$EncodedJwtClaimsSet = $JwtClaimsSet | ConvertTo-Base64Url
# Concatenate into the unsigned JSON Web Token (JWT).
$Jwt = [System.String]::Concat($EncodedJwtHeader, '.', $EncodedJwtClaimsSet)

# Generate a signature to sign the unsigned JSON Web Token.
$Signature = $Jwt | ConvertTo-Signature -Key ($Data.PrivateKey | ConvertFrom-SecureString -AsPlainText)
# Concatenate into the signed JSON Web Signature (JWS).
$Jws = [System.String]::Concat($Jwt, '.', $Signature)

# Prepare the Access/Bearer Token request.
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
    client_assertion      = $Jws
    client_id             = $Data.ClientId | ConvertFrom-SecureString -AsPlainText
}
$Query = @()
foreach ($k in $QueryData.Keys) {
    $Query += "$($k)=$([uri]::EscapeDataString($QueryData[$k]))"
}
if ($Query.Count -gt 0) { $Attributes.Uri = "$($Data.TokenUrl)?$($Query -join '&')" }
try {
    $Response = Invoke-RestMethod @Attributes
}
catch {
    Write-Error -Message "API call failed: $($_.Exception.Message)" -ErrorAction Stop
}

$oDev = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Response.access_token)"} -Method Get -Uri 'https://api-business.apple.com/v1/orgDevices'