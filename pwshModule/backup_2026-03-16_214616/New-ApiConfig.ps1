function New-ApiConfig {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default'
                ,  Mandatory = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('PrivateKey', 'pk')]
        [ValidateScript({if ($_.Length -notin 44..300) {
            throw "The length '$($_.Length)' of the private key indicates that it is not a valid private key."}; $true})]
        [Security.SecureString]
        $Key
        ,
        [Parameter(ParameterSetName = 'Default'
                ,  Mandatory = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('kid')]
        [ValidateScript({if ($_ -notmatch '^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$') {
            throw "The '$($_.ToString())' argument is not a valid Key ID pattern."}; $true})]
        [string]
        $KeyId
        ,
        [Parameter(ParameterSetName = 'Default'
                ,  Mandatory = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('cid', 'Subject', 'sub')]
        [ValidateScript({if ($_ -notmatch '^(?:BUSINESS|SCHOOL)API\.[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$') {
            throw "The '$($_.ToString())' argument is not a valid Client ID pattern."}; $true})]
        [string]
        $ClientId
        ,
        [Parameter(ParameterSetName = 'Default'
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('tid', 'Issuer', 'iss')]
        [ValidateScript({if ($_ -notmatch '^(?:BUSINESS|SCHOOL)API\.[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$') {
            throw "The '$($_.ToString())' argument is not a valid Team ID pattern."}; $true})]
        [string]
        $TeamId
        ,
        [Parameter(ParameterSetName = 'Default'
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('ttl')]
        [ValidateScript({if ($_ -lt [timespan]::FromSeconds(1) -or $_ -gt [timespan]::FromDays(180)) {
            throw "The '$($_.ToString())' argument is not within the allowed range. Supply an argument that is between '00:00:01' and '180.00:00:00' and then try the command again."}; $true})]
        [timespan]
        $TimeToLive = [timespan]::FromMinutes(15)
        ,
        [Parameter(ParameterSetName = 'Default'
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('tu')]
        [ValidateNotNullOrEmpty()]
        [uri]
        $TokenUrl = 'https://account.apple.com/auth/oauth2/v2/token'
        ,
        [Parameter(ParameterSetName = 'Default'
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('au')]
        [ValidateNotNullOrEmpty()]
        [uri]
        $ApiUrl = 'https://api-business.apple.com/v1'
        ,
        [Parameter()]
        [switch]
        $PassThru
        ,
        [Parameter(ParameterSetName = 'Interactive')]
        [switch]
        $Interactive
    )
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    if ($PSCmdlet.ParameterSetName -eq 'Interactive') {
        throw 'Interactive mode is not implemented yet.'
    }
    $ConfigTable = @{}
    $ConfigTable.Key = $Key
    $ConfigTable.KeyId = $KeyId
    $ConfigTable.ClientId = $ClientId
    if ($TeamId) { $ConfigTable.TeamId = $TeamId }
    $ConfigTable.TimeToLive = $TimeToLive
    $ConfigTable.TokenUrl = $TokenUrl
    $ConfigTable.ApiUrl = $ApiUrl
    $Script:Config = [PSCustomObject]$ConfigTable
    if ($PassThru) { $Script:Config }
    <#
    .SYNOPSIS
    Initiates a new API configuration.

    .DESCRIPTION
    Initiates a new API configuration for logging into Apple Business/School Manager.

    .PARAMETER Key
    The private key downloaded from Apple Business/School Manager. Used to sign the JWS Signing Input.

    .PARAMETER KeyId
    The Key ID (kid) used in the JSON Web Token JOSE (JavaScript Object Signing and Encryption) header.

    .PARAMETER ClientId
    The Client ID is used as the Subject (sub) claim in the JSON Web Token.

    .PARAMETER TeamId
    The Team ID is used as the Issuer (iss) claim in the JSON Web Token.
    Default: Same as ClientId

    .PARAMETER TimeToLive
    A TimeSpan object. It will be to calculate the Expiration Time (exp) claim in the JSON Web Token.
    Default: 15 minutes.

    .PARAMETER TokenUrl
    The TokenUrl is used for the Audience (aud) claim in the JSON Web Token.
    Default: https://account.apple.com/auth/oauth2/v2/token

    .PARAMETER ApiUrl
    The base URL for all the Apple Business/School Manager API endpoints.
    Default: https://api-business.apple.com/v1

    .PARAMETER PassThru
    Returns the resulting configuration.

    .NOTES
    #>
}