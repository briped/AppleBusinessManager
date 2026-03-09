function Initialize-RateLimitState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri
    )

    if (-not $Script:RateLimitStateFile) {
        $Script:RateLimitStateFile = Join-Path $env:APPDATA 'ApiRateLimitState.json'
    }

    if (-not $Script:ApiCache) {
        $Script:ApiCache = @{}
    }

    if (-not $Script:RateLimit) {
        if (Test-Path $Script:RateLimitStateFile) {
            try {
                $Script:RateLimit = Get-Content $Script:RateLimitStateFile -Raw |
                    ConvertFrom-Json -AsHashtable -Depth 5
            } catch {
                Write-Warning "$($MyInvocation.MyCommand.Name): Failed to load rate limit state: $_"
                $Script:RateLimit = @{}
            }
        } else {
            $Script:RateLimit = @{}
        }
    }

    $hostKey = $Uri.Host
    if (-not $Script:RateLimit.ContainsKey($hostKey)) {
        $Script:RateLimit[$hostKey] = @{
            DelayMs        = 0
            LastRequestAt  = $null
            ConsecutiveOks = 0
        }
    }
    <#
    .SYNOPSIS
        Initializes rate limit state for a given API host.
    .DESCRIPTION
        Ensures $Script:RateLimit, $Script:ApiCache, and $Script:RateLimitStateFile are
        initialized. Loads persisted state from disk on first call. Creates a default
        state entry for the host if one does not already exist.
    .PARAMETER Uri
        The URI of the API endpoint. The host portion is used as the state key.
    .NOTES
        State is stored in $Script:RateLimit, keyed by hostname.
        Persisted to $Script:RateLimitStateFile (JSON) across sessions.
    #>
}