function New-Jwt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('PrivateKey', 'pk')]
        [securestring]
        $Key
        ,
        [Parameter(Mandatory = $true)]
        [Alias('kid')]
        [string]
        $KeyId
        ,
        [Parameter(Mandatory = $true)]
        [Alias('iss')]
        [string]
        $Issuer
        ,
        [Parameter(Mandatory = $true)]
        [Alias('sub')]
        [string]
        $Subject
        ,
        [Parameter()]
        [Alias('aud')]
        [uri]
        $Audience = 'https://account.apple.com/auth/oauth2/v2/token'
        ,
        [Parameter()]
        [Alias('ttl')]
        [timespan]
        $TimeToLive = (New-TimeSpan -Hours 1)
    )
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Begin: $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    $Now = [System.DateTimeOffset]::Now
    $JwtId = [guid]::NewGuid().Guid
    # JOSE (JavaScript Object Signing and Encryption) header.
    # https://datatracker.ietf.org/doc/html/rfc7515#section-4
    $Header = @{
        kid = $KeyId
        alg = 'ES256'
    } | ConvertTo-Json -Compress

    # JWT (JSON Web Token) Claims Set.
    # https://datatracker.ietf.org/doc/html/rfc7519#section-4
    $Payload = @{
        aud = $Audience
        iss = $Issuer
        sub = $Subject
        iat = $Now.ToUnixTimeSeconds()
        exp = $Now.AddSeconds($TimeToLive.TotalSeconds).ToUnixTimeSeconds()
        jti = $JwtId
    } | ConvertTo-Json -Compress

    # Base64URL encode the Header and the Payload
    $EncodedHeader = ConvertTo-Base64Url -String $Header
    $EncodedPayload = ConvertTo-Base64Url -String $Payload

    # Concatenate the encoded header and payload into the unsigned JSON Web Token
    $JwsSigningInput = [System.String]::Concat($EncodedHeader, '.', $EncodedPayload)
    # JwsCompactSerialization
    $JwsCompactSerialization = $JwsSigningInput | New-JwsCompactSerialization -Key $Key
    $JwsCompactSerialization
    <#
    .SYNOPSIS
    Create an unsigned JWT for Apple Business/School Manager authentication.

    .DESCRIPTION
    This function creates a signed JSON Web Token (JWT) for accessing the Apple Business/School Manager (ABM/ASM) API.

    .PARAMETER KeyId
    The Key ID (kid) used in the JWT JOSE header to identify the signing key.

    .PARAMETER Issuer
    The issuer (iss) claim identifying who created the JWT. Typically your Team ID or organization identifier.

    .PARAMETER Subject
    The subject (sub) claim identifying the principal that is the subject of the JWT.

    .PARAMETER TimeToLive
    The duration for which the JWT is valid. Defaults to 1 hour. Maximum allowed by Apple is 180 days.

    .OUTPUTS
    System.String
    An unsigned JWT in the format "header.payload".

    .EXAMPLE
    New-Jwt -KeyId 'ABC123' -Issuer 'my-team-id' -Subject 'my-subject'

    Output:
    eyJraWQiOiJBQkMxMjMiLCJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJodHRwczovL2FjY291bnQuYXBwbGUuY29tL2F1dGgvb2F1dGgyL3YyL3Rva2VuIiwiaXNzIjoibXktdGVhbS1pZCIsInN1YiI6Im15LXN1YmplY3QiLCJpYXQiOjE2OTk1MzM2MDAsIm5iZiI6MTY5OTUzMzYwMCwiZXhwIjoxNjk5NTM3MjAwLCJqdGkiOiJhYmNkZWZnaC0xMjM0LTU2Nzgtd3l6YSJ9

    This example demonstrates creating an unsigned JWT with default 1-hour validity.

    .EXAMPLE
    New-Jwt -KeyId 'ABC123' -Issuer 'my-team-id' -Subject 'my-subject' -Validity (New-TimeSpan -Hours 2)

    Output:
    eyJraWQiOiJBQkMxMjMiLCJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJodHRwczovL2FjY291bnQuYXBwbGUuY29tL2F1dGgvb2F1dGgyL3YyL3Rva2VuIiwiaXNzIjoibXktdGVhbS1pZCIsInN1YiI6Im15LXN1YmplY3QiLCJpYXQiOjE2OTk1MzM2MDAsIm5iZiI6MTY5OTUzMzYwMCwiZXhwIjoxNjk5NTQwODAwLCJqdGkiOiJhYmNkZWZnaC0xMjM0LTU2Nzgtd3l6YSJ9

    This example demonstrates creating an unsigned JWT with a custom 2-hour validity period.

    .NOTES
    The JWT created by this function is unsigned. Use New-JsonWebSignature to sign it with 
    your private key before sending to Apple APIs.
    #>
}
