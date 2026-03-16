function Invoke-PaginatedApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [uri]
        $Uri,

        [Parameter(Mandatory = $false)]
        [switch]
        $Raw
    )

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Starting paginated request. Uri: $Uri, Raw: $Raw"

    $currentUri = $Uri
    $pageCount = 0

    do {
        $pageCount++
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Fetching page $pageCount from $currentUri"

        try {
            $Response = Invoke-ApiRequest -Method Get -Uri $currentUri

            # Output results from this page
            if ($Raw) {
                $Response
            }
            else {
                $Response.data
            }

            # Check for next page
            $currentUri = $Response.links.next
            if ($currentUri) {
                Write-Debug -Message "$($MyInvocation.MyCommand.Name): Found next page link, continuing pagination"
            }
        }
        catch {
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Error on page $pageCount - delegating to caller"
            throw
        }

    } while ($currentUri)

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Pagination complete. Total pages retrieved: $pageCount"
    <#
    .SYNOPSIS
    Invokes paginated API requests with automatic link following.

    .DESCRIPTION
    Internal helper function that handles pagination for API requests. Automatically follows 'next' links
    in API responses and returns all results. Eliminates duplicate pagination logic across multiple Get-* functions.

    .PARAMETER Uri
    The initial URI to request.

    .PARAMETER Raw
    Switch to return the complete API response object instead of just the data.

    .OUTPUTS
    System.Object or System.Object[]
    Returns parsed response data or complete response objects based on Raw parameter.

    .EXAMPLE
    Invoke-PaginatedApiRequest -Uri 'https://api-business.apple.com/v1/orgDevices?limit=50'
    Returns all device data, following pagination links automatically.

    .EXAMPLE
    Invoke-PaginatedApiRequest -Uri $Uri -Raw
    Returns complete API response objects including metadata and links.

    .NOTES
    This is an internal helper function used by public Get-* functions in the module.
    Centralizes pagination logic to fix and maintain in one location.
    #>
}
