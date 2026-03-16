function Get-CachedResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $TtlSeconds = 3600  # Default: 1 hour
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

    # Load cache from disk if not already loaded
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

    # Check if URI is in cache
    if (-not $Script:ApiCache.ContainsKey($Uri)) {
        Write-Debug "$($MyInvocation.MyCommand.Name): Cache miss for URI: $Uri"
        return $null
    }

    $CacheEntry = $Script:ApiCache[$Uri]
    $CacheTime = [datetime]::Parse($CacheEntry.Timestamp)
    $Age = ([datetime]::Now - $CacheTime).TotalSeconds

    # Check if cache has expired
    if ($Age -gt $TtlSeconds) {
        Write-Debug "$($MyInvocation.MyCommand.Name): Cache expired for URI: $Uri (age: $Age seconds, TTL: $TtlSeconds seconds)"
        return $null
    }

    Write-Debug "$($MyInvocation.MyCommand.Name): Cache hit for URI: $Uri (age: $Age seconds)"
    return $CacheEntry.Data
    <#
    .SYNOPSIS
        Retrieves a cached API response if it exists and hasn't expired.

    .DESCRIPTION
        Checks the in-memory and persistent cache for a response associated with a URI.
        Returns the cached response data only if the cache entry exists and is within
        the TTL (time to live) window.

    .PARAMETER Uri
        The URI of the API endpoint to look up in the cache.

    .PARAMETER TtlSeconds
        The time to live for cache entries in seconds. Default is 3600 (1 hour).
        Entries older than this are considered expired and not returned.

    .OUTPUTS
        System.Object or $null
        Returns the cached response data if found and valid, otherwise $null.

    .EXAMPLE
        $cached = Get-CachedResponse -Uri 'https://api.example.com/v1/devices?limit=500'
        if ($cached) {
            return $cached
        }

    .NOTES
        This is an internal helper function. Cache is stored in $Script:ApiCache and
        persisted to $env:APPDATA\.ApiResponseCache.json. Cache miss returns $null.
    #>
}
