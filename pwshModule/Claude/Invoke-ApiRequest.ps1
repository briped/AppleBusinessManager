function Invoke-ApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ApiUrl')]
        [uri]$Uri,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Body,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ContentType = 'application/json',

        [Parameter(Mandatory = $false)]
        [switch]$BypassCache,

        [Parameter(Mandatory = $false)]
        [int]$CacheTtlSeconds = 300
    )

    Write-Debug "$($MyInvocation.MyCommand.Name): $(
        $PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue
    )"

    #region --- Configuration & token validation ---

    if (-not $Script:Config -or
        -not $Script:Config.Key -or
        -not $Script:Config.KeyId -or
        -not $Script:Config.ClientId -or
        -not $Script:Config.TokenUrl -or
        -not $Script:Config.TimeToLive) {
        throw 'Configuration is missing. Please run New-ApiConfig or Import-ApiConfig first.'
    }

    if (-not $Script:Api.AccessToken -or
        $Script:Api.ExpiresAt -lt [datetime]::Now.AddSeconds(30)) {

        Write-Debug "$($MyInvocation.MyCommand.Name): Requesting new access token."
        $tokenParams = @{
            Key        = $Script:Config.Key
            KeyId      = $Script:Config.KeyId
            ClientId   = $Script:Config.ClientId
            TokenUrl   = $Script:Config.TokenUrl
            TimeToLive = $Script:Config.TimeToLive
        }
        $tokenResponse = Request-AccessToken @tokenParams
        $Script:Api.AccessToken = $tokenResponse.access_token
        $Script:Api.ExpiresAt   = [datetime]::Now.AddSeconds($tokenResponse.expires_in)
    }

    #endregion

    #region --- Rate limit state initialization ---

    Initialize-RateLimitState -Uri $Uri

    #endregion

    #region --- Cache check (GET only) ---

    $cacheKey = "$Method|$Uri"
    if ($Method -eq 'GET' -and -not $BypassCache) {
        $cached = $Script:ApiCache[$cacheKey]
        if ($cached -and $cached.Expires -gt [datetime]::Now) {
            Write-Debug "$($MyInvocation.MyCommand.Name): Cache HIT for $cacheKey"
            return $cached.Data
        }
        Write-Debug "$($MyInvocation.MyCommand.Name): Cache MISS for $cacheKey"
    }

    #endregion

    #region --- Adaptive rate limit delay ---

    Invoke-RateLimitDelay -Uri $Uri

    #endregion

    #region --- Request with retry on 429 ---

    $headers = @{ Authorization = "Bearer $($Script:Api.AccessToken)" }
    $requestParams = @{
        Headers         = $headers
        Method          = $Method
        ContentType     = $ContentType
        UseBasicParsing = $true
        Uri             = $Uri
        ErrorAction     = 'Stop'
    }
    if ($Body) {
        $requestParams['Body'] = $Body
    }

    $maxRetries = 5
    $attempt    = 0
    $backoffMs  = 1000

    while ($true) {
        $attempt++
        $Script:RateLimit[$Uri.Host]['LastRequestAt'] = [datetime]::Now.ToString('o')

        try {
            $response = Invoke-WebRequest @requestParams
            $parsed   = $response.Content | ConvertFrom-Json -Depth 10

            Update-RateLimitOnSuccess -Uri $Uri
            
            if ($Method -eq 'GET') {
                $Script:ApiCache[$cacheKey] = @{
                    Expires = [datetime]::Now.AddSeconds($CacheTtlSeconds)
                    Data    = $parsed
                }
                Write-Debug "$($MyInvocation.MyCommand.Name): Cached response for ${CacheTtlSeconds}s."
            }

            return $parsed

        } catch [System.Net.WebException] {
            $statusCode = [int]$_.Exception.Response.StatusCode

            if ($statusCode -eq 429) {
                if ($attempt -ge $maxRetries) {
                    throw "Rate limited (429) after $maxRetries retries on $Uri"
                }

                Update-RateLimitOn429 -Uri $Uri -BackoffMs $backoffMs
                Write-Warning "$($MyInvocation.MyCommand.Name): 429 received. New learned delay: $($Script:RateLimit[$Uri.Host].DelayMs)ms. Waiting ${backoffMs}ms before retry $attempt/$maxRetries..."
                Start-Sleep -Milliseconds $backoffMs
                $backoffMs = $backoffMs * 2

            } else {
                throw
            }
        }
    }

    #endregion
    <#
    .SYNOPSIS
        Makes an authenticated API request with adaptive rate limiting and response caching.
    .DESCRIPTION
        Handles token management, automatic retry with exponential backoff on 429 responses,
        adaptive inter-request delay, and GET response caching. Rate limit state is persisted
        to disk per API host so learned delays survive between sessions.
    .PARAMETER Uri
        The full URI of the API endpoint.
    .PARAMETER Method
        The HTTP method to use (GET, POST, PATCH, DELETE, etc.).
    .PARAMETER Body
        Optional request body (for POST/PATCH/PUT).
    .PARAMETER ContentType
        Content type of the request body. Defaults to 'application/json'.
    .PARAMETER BypassCache
        If set, skips the cache and always makes a live request (still updates cache).
    .PARAMETER CacheTtlSeconds
        How long GET responses are cached in seconds. Default: 300 (5 minutes).
    .NOTES
        Rate limit state is persisted in $Script:RateLimitStateFile.
        Cache is held in $Script:ApiCache (in-memory, per session).
    #>
}