function Request-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [TypeName]
        $ParameterName
    )
    $Data = Import-Clixml -Path '.briped@daredevil.xml'

    $Header = @{
        alg = $Data.TokenAlgorithm
        kid = $Data.KeyId | ConvertFrom-SecureString -AsPlainText
        typ = $Data.TokenType
    }
    $Payload = @{
        iat = [System.DateTimeOffset]::Now.ToUnixTimeSeconds()
        exp = [System.DateTimeOffset]::Now.AddHours(1).ToUnixTimeSeconds()
        aud = $Data.TokenUrl
        sub = $Data.ClientId | ConvertFrom-SecureString -AsPlainText
        iss = $Data.TeamId | ConvertFrom-SecureString -AsPlainText
        jti = [guid]::NewGuid().Guid
    }

    $TokenData = $Header | ConvertTo-Json -Compress | ConvertTo-Base64Url
    $TokenData += '.'
    $TokenData += $Payload | ConvertTo-Json -Compress | ConvertTo-Base64Url
    $TokenSignature = $TokenData | ConvertTo-Signature -Key ($Data.PrivateKey  | ConvertFrom-SecureString -AsPlainText)
    $Jwt = $TokenData
    $Jwt += '.'
    $Jwt += $TokenSignature

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
        grant_type = 'client_credentials'
        client_id = $Data.ClientId | ConvertFrom-SecureString -AsPlainText
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        client_assertion = $Jwt
        scope = 'business.api'
    }
    $Query = @()
    foreach ($k in $QueryData.Keys) {
        $Query += "$($k)=$([uri]::EscapeDataString($QueryData[$k]))"
    }
    if ($Query.Count -gt 0) { $Attributes.Uri = "$($Data.TokenUrl)?$($Query -join '&')" }
    try {
        $Response = Invoke-RestMethod @Attributes
        Write-Host "Authentication successful!"
        Write-Host "Response: $($Response | ConvertTo-Json)"
    }
    catch {
        Write-Host "API call failed: $($_.Exception.Message)"
    }
    <#
    .NOTES
    https://developer.apple.com/documentation/apple-school-and-business-manager-api/implementing-oauth-for-the-apple-school-and-business-manager-api
    #>
}