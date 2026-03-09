function Invoke-ApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ApiUrl')]
        [uri]
        $Uri
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method
        ,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Body
        ,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ContentType = 'application/json'
    )
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"

    # Check for the configuration and its keys.
    if (!$Script:Config -or !$Script:Config.Key -or !$Script:Config.KeyId -or 
        !$Script:Config.ClientId -or !$Script:Config.TokenUrl -or !$Script:Config.TimeToLive) {
        throw "Configuration is missing. Please create a configuration using New-ApiConfig or import one using Import-ApiConfig."
    }
    $Attributes = @{
        Key        = $Script:Config.Key
        KeyId      = $Script:Config.KeyId
        ClientId   = $Script:Config.ClientId
        TokenUrl   = $Script:Config.TokenUrl
        TimeToLive = $Script:Config.TimeToLive
    }
    # Check for access token and its validity.
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($Script:Api | ConvertTo-Json -Compress)"
    $Global:DebugApi = $Script:Api
    if (!$Script:Api -or !$Script:Api.AccessToken -or !$Script:Api.ExpiresAt -or 
        $Script:Api.ExpiresAt -lt [datetime]::Now.AddSeconds(30)) {
        # Request a new access token.
        $Response = Request-AccessToken @Attributes
        $Script:Api.AccessToken = $Response.access_token
        $Script:Api.ExpiresAt = [datetime]::Now.AddSeconds($Response.expires_in)
    }
    $Headers = @{
        Authorization = "Bearer $($Script:Api.AccessToken)"
    }
    $Attributes = @{
        Headers = $Headers
        Method = $Method
        ContentType = $ContentType
        UseBasicParsing = $true
        Uri = $Uri
    }
    if ($Body) { $Attributes.Body = $Body }
    $Response = Invoke-WebRequest @Attributes
    $Response.Content | ConvertFrom-Json -Depth 10
    <#
    .SYNOPSIS
    .DESCRIPTION
    .PARAMETER Uri
    .PARAMETER Method
    .PARAMETER Body
    .PARAMETER ContentType
    .NOTES
    #>
}