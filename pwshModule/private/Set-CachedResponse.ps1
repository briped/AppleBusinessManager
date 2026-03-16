function Set-CachedResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]
        $ResponseData,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $MaxCacheSizeMB = 100
    )

    if (-not $Script:ApiCacheFile) {
        # Determine the cache file path from config or use current directory
        if ($Script:Config.ResponseCachePath) {
            $Script:ApiCacheFile = $Script:Config.ResponseCachePath
        }
        else {
            # Default to current directory
            $Script:ApiCacheFile = Join-Path (Get-Location).Path '.ApiResponseCache.json'
        }
    }

    # Initialize cache if needed
    if (-not $Script:ApiCache) {
        if (Test-Path $Script:ApiCacheFile) {
            try {
                $Script:ApiCache = Get-Content $Script:ApiCacheFile -Raw |
                    ConvertFrom-Json -AsHashtable -Depth 10
            } catch {
                Write-Debug "$($MyInvocation.MyCommand.Name): Failed to load response cache: $_"
                $Script:ApiCache = @{}
            }
        } else {
            $Script:ApiCache = @{}
        }
    }

    # Store response with timestamp
    $Script:ApiCache[$Uri] = @{
        Data      = $ResponseData
        Timestamp = [datetime]::Now.ToString('o')
    }

    try {
        # Persist to disk
        $Script:ApiCache | ConvertTo-Json -Depth 10 |
            Set-Content -Path $Script:ApiCacheFile -Encoding UTF8

        # Check cache file size and warn if too large
        $CacheFile = Get-Item $Script:ApiCacheFile -ErrorAction SilentlyContinue
        if ($CacheFile) {
            $SizeMB = $CacheFile.Length / 1MB
            if ($SizeMB -gt $MaxCacheSizeMB) {
                Write-Warning "$($MyInvocation.MyCommand.Name): Cache file is ${SizeMB}MB, exceeds limit of ${MaxCacheSizeMB}MB. Consider clearing old entries."
            }
        }

        Write-Debug "$($MyInvocation.MyCommand.Name): Cached response for URI: $Uri"
    } catch {
        Write-Warning "$($MyInvocation.MyCommand.Name): Could not persist cache: $_"
    }
    <#
    .SYNOPSIS
        Caches an API response for future retrieval.

    .DESCRIPTION
        Stores an API response data with a timestamp in the cache. The response is stored
        in memory and persisted to disk for retrieval across PowerShell sessions.
        Warns if the cache file exceeds the specified size limit.

    .PARAMETER Uri
        The URI of the API endpoint associated with this response. Used as cache key.

    .PARAMETER ResponseData
        The response data to cache (typically a PowerShell object or array).

    .PARAMETER MaxCacheSizeMB
        The maximum allowed cache file size in megabytes. Default is 100MB.
        A warning is issued if the cache file exceeds this size.

    .EXAMPLE
        $response = Invoke-ApiRequest -Method Get -Uri 'https://api.example.com/v1/devices'
        Set-CachedResponse -Uri $response_uri -ResponseData $response

    .NOTES
        This is an internal helper function. Cache is persisted to
        $env:APPDATA\.ApiResponseCache.json. All timestamps are in ISO 8601 format.
    #>
}
