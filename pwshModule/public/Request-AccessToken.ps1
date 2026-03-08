function Request-AccessToken {
    [CmdletBinding()]
    param (
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
        [Alias('Subject', 'sub', 'TeamId', 'Issuer', 'iss', 'cid')]
        [string]
        $ClientId
        ,
        [Parameter()]
        [uri]
        $TokenUrl = 'https://account.apple.com/auth/oauth2/v2/token'
        ,
        [Parameter()]
        [Alias('ttl')]
        [timespan]
        $TimeToLive = (New-TimeSpan -Hours 1)
    )
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    $Uri = $TokenUrl
    $Attributes = @{
        Key        = $Key
        KeyId      = $KeyId
        Issuer     = $ClientId
        Subject    = $ClientId
        Audience   = $TokenUrl
        TimeToLive = New-TimeSpan -Hours 1
    }
    $Jwt = New-Jwt @Attributes
    Write-Host $Jwt -ForegroundColor Magenta
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): `$Jwt: [$($Jwt.Split('.')[0..1].ForEach({$_|ConvertFrom-Base64Url}) -join ',')]"

    # Specify the Query Data.
    $QueryData = @{
        grant_type            = 'client_credentials'
        scope                 = 'business.api'
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion      = $Jwt
        client_id             = $ClientId
    }

    # Join the Query Data into a single string.
    $Query = @()
    foreach ($k in $QueryData.Keys) {
        $Query += "$($k)=$([uri]::EscapeDataString($QueryData[$k]))"
    }
    # Update the Uri, if the Query contained any data.
    if ($Query.Count -gt 0) { $Uri = "$($TokenUrl)?$($Query -join '&')" }

    # Prepare the Access/Bearer Token request.
    $Headers = @{
        'Host'         = 'account.apple.com'
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    $Attributes = @{
        Uri     = $Uri
        Method  = 'POST'
        Headers = $Headers
    }
    try {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Process: Invoke-RestMethod $($Attributes | ConvertTo-Json -Compress)"
        $Response = Invoke-RestMethod @Attributes
        $Response
    }
    catch {
        throw $_
    }
    <#
    .SYNOPSIS
    Request an access token from Apple Business/School Manager API.

    .DESCRIPTION
    This function requests an OAuth 2.0 access token from Apple's authentication service for use with the Apple Business/School Manager API.
    It creates a signed JWT assertion and exchanges it for an access token using the client credentials grant flow.
    https://developer.apple.com/documentation/apple-school-and-business-manager-api/implementing-oauth-for-the-apple-school-and-business-manager-api

    .PARAMETER Key
    The private key used to sign the JWT assertion. Provided as a SecureString for security.

    .PARAMETER KeyId
    The Key ID (kid) identifying which private key is being used for signing.

    .PARAMETER TeamId
    Your Apple Team ID, used as the issuer (iss) claim in the JWT.

    .PARAMETER ClientId
    The client identifier, used as the subject (sub) claim in the JWT.

    .PARAMETER TokenUrl
    The OAuth2 Token URL.

    .PARAMETER TimeToLive
    The duration for which the JWT is valid. Defaults to 1 hour. Maximum allowed by Apple is 180 days.

    .INPUTS
    None. This function does not accept pipeline input.

    .OUTPUTS
    System.String
    The access token string for authenticating subsequent API requests.

    .EXAMPLE
    Request-AccessToken -PrivateKey $key -KeyId 'ABC123' -TeamId 'TEAM123' -ClientId 'com.example.app'

    eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9...

    This example demonstrates requesting an access token with the required credentials.

    .NOTES
    The access token is typically valid for 15 minutes. Store it securely and request a new token when it expires.

    https://developer.apple.com/documentation/apple-school-and-business-manager-api/implementing-oauth-for-the-apple-school-and-business-manager-api
    #>
}
New-Alias -Force -Name 'rqat' -Value 'Request-AccessToken'