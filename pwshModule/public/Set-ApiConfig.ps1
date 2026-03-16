function Set-ApiConfig {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('PSPath')]
        [ValidateScript({if (!(Test-Path -PathType Leaf -Path $_)) { 
            throw "Path '$_' could not be found or is not a file." }; $true})]
        [System.IO.FileInfo]
        $Path,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [uri]
        $ApiUrl,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [uri]
        $TokenUrl,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [timespan]
        $TimeToLive,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $RateLimitStatePath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $ResponseCachePath,

        [Parameter()]
        [switch]
        $PassThru
    )

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"

    # Load the existing configuration
    $Configuration = Import-Clixml -Path $Path

    # Update fields that were provided
    if ($PSBoundParameters.ContainsKey('ApiUrl')) {
        $Configuration.ApiUrl = $ApiUrl
        Write-Debug "Updated ApiUrl to $ApiUrl"
    }

    if ($PSBoundParameters.ContainsKey('TokenUrl')) {
        $Configuration.TokenUrl = $TokenUrl
        Write-Debug "Updated TokenUrl to $TokenUrl"
    }

    if ($PSBoundParameters.ContainsKey('TimeToLive')) {
        $Configuration.TimeToLive = $TimeToLive
        Write-Debug "Updated TimeToLive to $TimeToLive"
    }

    if ($PSBoundParameters.ContainsKey('RateLimitStatePath')) {
        $Configuration.RateLimitStatePath = $RateLimitStatePath
        Write-Debug "Updated RateLimitStatePath to $RateLimitStatePath"
    }

    if ($PSBoundParameters.ContainsKey('ResponseCachePath')) {
        $Configuration.ResponseCachePath = $ResponseCachePath
        Write-Debug "Updated ResponseCachePath to $ResponseCachePath"
    }

    # Save the updated configuration
    if ($PSCmdlet.ShouldProcess($Path, "Save updated API configuration")) {
        $Configuration | Export-Clixml -Path $Path -Force
        Write-Verbose "Configuration saved to $Path"
    }

    if ($PassThru) {
        $Configuration
    }

    <#
    .SYNOPSIS
    Modifies an existing API configuration stored in a CliXML file.

    .DESCRIPTION
    Updates individual fields of an API configuration file without needing to recreate
    the entire configuration. Provides a way to update endpoints, timeouts, cache paths,
    and other settings after initial configuration creation.

    .PARAMETER Path
    The filepath to the CliXML configuration file to modify.

    .PARAMETER ApiUrl
    The Apple Business Manager API base URL. Optional update.

    .PARAMETER TokenUrl
    The OAuth2 token endpoint URL. Optional update.

    .PARAMETER TimeToLive
    The JWT token lifetime. Optional update.

    .PARAMETER RateLimitStatePath
    The file path where rate limit state is persisted. Optional update.
    If not set, defaults to the current working directory.

    .PARAMETER ResponseCachePath
    The file path where API response cache is persisted. Optional update.
    If not set, defaults to the current working directory.

    .PARAMETER PassThru
    Returns the updated configuration object.

    .EXAMPLE
    Set-ApiConfig -Path ./config.xml -RateLimitStatePath ./data/.ApiRateLimitState.json
    Updates the rate limit state path in the configuration file.

    .EXAMPLE
    Set-ApiConfig -Path ./config.xml -ResponseCachePath "./data/.ApiResponseCache.json" -PassThru
    Updates the response cache path and returns the modified configuration.

    .NOTES
    This function allows you to configure file paths relative to your project directory
    rather than storing persistent data in user-specific locations like $env:APPDATA.
    #>
}
