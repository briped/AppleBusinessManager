function New-ApiUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $PathSegments,

        [Parameter(Mandatory = $false)]
        [string]
        $QueryString
    )

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Building URI. PathSegments: $($PathSegments -join '/'), QueryString: '$QueryString'"

    $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)

    foreach ($segment in $PathSegments) {
        if (-not [string]::IsNullOrEmpty($segment)) {
            $UriBuilder.Path += "/$([uri]::EscapeDataString($segment))"
        }
    }

    if (-not [string]::IsNullOrEmpty($QueryString)) {
        $UriBuilder.Query = $QueryString
    }

    $UriBuilder.Uri
    <#
    .SYNOPSIS
    Constructs an Apple Business Manager API URI with path segments and optional query parameters.

    .DESCRIPTION
    Internal helper function that builds a properly formatted URI for API requests. Handles URL escaping of path segments and
    query string construction in a single operation to reduce code duplication across Get-* functions.

    .PARAMETER PathSegments
    An array of path segments to append to the API base URL. Each segment is URL-escaped.

    .PARAMETER QueryString
    An optional query string to append to the URI (pre-formatted).

    .OUTPUTS
    System.Uri
    Returns the constructed URI.

    .EXAMPLE
    $Uri = New-ApiUri -PathSegments @('orgDevices', 'ABC123', 'appleCareCoverage')
    Creates URI: https://api-business.apple.com/v1/orgDevices/ABC123/appleCareCoverage

    .EXAMPLE
    $Uri = New-ApiUri -PathSegments @('mdmServers') -QueryString 'limit=50&fields[mdmServers]=serverName'
    Creates URI with query parameters.

    .NOTES
    This is an internal helper function used by public functions in the module.
    #>
}
