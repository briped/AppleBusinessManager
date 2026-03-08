function New-JwsCompactSerialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true
                ,  Position = 0)]
        [Alias('PrivateKey', 'pk')]
        [securestring]
        $Key
        ,
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  Position = 1)]
        [Alias('JwsSigningInput', 'si')]
        [string]
        $SigningInput
    )
    begin {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin: $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"

        # Ensure the key is in the proper format.
        $KeyString = [System.String]::Concat((($Key | ConvertFrom-SecureString -AsPlainText).Split("`n") | Where-Object { $_ -notmatch '^-----|^$' }))

        # Convert and import the key.
        $KeyBytes = [Convert]::FromBase64String($KeyString)
        $ECDsa = [System.Security.Cryptography.ECDsa]::Create()
        $ECDsa.ImportPkcs8PrivateKey($KeyBytes, [ref]$null)
    }
    process {
        if ($PSCmdlet.MyInvocation.PipelineLength -gt 0) { Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Process: $($SigningInput | ConvertTo-Json -Compress)" }
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): `$SigningInput: [$($SigningInput.Split('.').ForEach({$_|ConvertFrom-Base64Url}) -join ',')]"
        $JwsPayload = [System.Text.Encoding]::UTF8.GetBytes($SigningInput)
        $SignedJwsPayload = $ECDsa.SignData($JwsPayload, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
        $JwsSignature = ConvertTo-Base64Url -Bytes $SignedJwsPayload
        $JwsCompactSerialization = [System.String]::Concat($SigningInput, '.', $JwsSignature)
        $JwsCompactSerialization
    }
    end {
        # Clear and remove all variables that the decrypted key have been stored in.
        $KeyString = $KeyBytes = $ECDsa = $JwsPayload = $SignedJwsPayload = $null
        Remove-Variable -Force -Name KeyString,KeyBytes,ECDsa,JwsPayload,SignedJwsPayload -ErrorAction SilentlyContinue
    }
    <#
    .SYNOPSIS
    Create a signed JSON Web Token as a JWS Compact Serilization

    .DESCRIPTION
    This function takes an unsigned JSON Web Token (JWT) and signs it using a private key 
    to produce a JSON Web Signature (JWS) as defined in RFC7515.
    https://datatracker.ietf.org/doc/html/rfc7515

    .PARAMETER Key
    The private key used to sign the JWT. Provided as a SecureString for security.

    .PARAMETER SigningInput
    The unsigned JWT in the format of "header.payload" to be signed.

    .INPUTS
    System.String
    An unsigned JWT can be piped to this function.

    .OUTPUTS
    System.String
    A signed JSON Web Signature (JWS) in the format "header.payload.signature".

    .EXAMPLE
    New-JwsCompactSerialization -Key $key -SigningInput $UnsignedJwt

    Output:
    eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature

    .EXAMPLE
    $UnsignedJwt | New-JwsCompactSerialization -Key $key

    Output:
    eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature

    .NOTES
    #>
}
