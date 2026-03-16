function Clear-CacheEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [Parameter(Mandatory = $false)]
        [switch]
        $ClearExpired,

        [Parameter(Mandatory = $false)]
        [switch]
        $ClearAll,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $TtlSeconds = 3600
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

    if ($ClearAll) {
        $Script:ApiCache.Clear()
        Write-Debug "$($MyInvocation.MyCommand.Name): Cleared all cache entries"
    }
    elseif ($ClearExpired) {
        $Removed = 0
        $Now = [datetime]::Now
        $KeysToRemove = @()

        foreach ($Key in $Script:ApiCache.Keys) {
            $CacheTime = [datetime]::Parse($Script:ApiCache[$Key].Timestamp)
            $Age = ($Now - $CacheTime).TotalSeconds

            if ($Age -gt $TtlSeconds) {
                $KeysToRemove += $Key
                $Removed++
            }
        }

        foreach ($Key in $KeysToRemove) {
            $Script:ApiCache.Remove($Key)
        }

        Write-Debug "$($MyInvocation.MyCommand.Name): Removed $Removed expired cache entries"
    }
    elseif ($Uri) {
        if ($Script:ApiCache.ContainsKey($Uri)) {
            $Script:ApiCache.Remove($Uri)
            Write-Debug "$($MyInvocation.MyCommand.Name): Cleared cache entry for URI: $Uri"
        }
    }

    try {
        # Persist changes to disk
        if ($Script:ApiCache.Count -gt 0) {
            $Script:ApiCache | ConvertTo-Json -Depth 10 |
                Set-Content -Path $Script:ApiCacheFile -Encoding UTF8
        } else {
            # Remove cache file if empty
            if (Test-Path $Script:ApiCacheFile) {
                Remove-Item $Script:ApiCacheFile -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Warning "$($MyInvocation.MyCommand.Name): Could not update cache file: $_"
    }
    <#
    .SYNOPSIS
        Removes cache entries from the API response cache.

    .DESCRIPTION
        Clears one or more cache entries from the persistent API response cache.
        Can remove specific URIs, expired entries, or clear the entire cache.
        Changes are persisted to disk.

    .PARAMETER Uri
        The specific URI to remove from the cache. If not specified with other
        parameters, uses ClearExpired or ClearAll logic.

    .PARAMETER ClearExpired
        Remove all cache entries that have exceeded their TTL (time to live).

    .PARAMETER ClearAll
        Remove all cache entries.

    .PARAMETER TtlSeconds
        The time to live threshold in seconds when using ClearExpired.
        Default is 3600 (1 hour).

    .EXAMPLE
        Clear-CacheEntry -Uri 'https://api.example.com/v1/devices/123'
        # Removes the cache entry for a specific device

    .EXAMPLE
        Clear-CacheEntry -ClearExpired -TtlSeconds 7200
        # Removes all cache entries older than 2 hours

    .EXAMPLE
        Clear-CacheEntry -ClearAll
        # Removes all cache entries and deletes the cache file

    .NOTES
        This is an internal helper function. Cache is persisted to
        $env:APPDATA\.ApiResponseCache.json. If cache becomes empty, the file is deleted.
    #>
}
