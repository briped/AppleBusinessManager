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

    # Initialize rate limit state
    Initialize-RateLimitState -Uri $Uri

    # Request access token if needed
    $tokenAttributes = @{
        Key        = $Script:Config.Key
        KeyId      = $Script:Config.KeyId
        ClientId   = $Script:Config.ClientId
        TokenUrl   = $Script:Config.TokenUrl
        TimeToLive = $Script:Config.TimeToLive
    }

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Current API state: $($Script:Api | ConvertTo-Json -Compress)"
    $Global:DebugApi = $Script:Api

    if (!$Script:Api -or !$Script:Api.AccessToken -or !$Script:Api.ExpiresAt -or 
        $Script:Api.ExpiresAt -lt [datetime]::Now.AddSeconds(30)) {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Token expired or missing, requesting new token"
        $Response = Request-AccessToken @tokenAttributes
        $Script:Api.AccessToken = $Response.access_token
        $Script:Api.ExpiresAt = [datetime]::Now.AddSeconds($Response.expires_in)
    }

    # Check cache for GET requests (safe to cache as they're idempotent)
    if ($Method -eq 'Get') {
        $cached = Get-CachedResponse -Uri $Uri.AbsoluteUri
        if ($null -ne $cached) {
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Returning cached response for URI: $Uri"
            return $cached
        }
    }

    # Prepare request
    $Headers = @{
        Authorization = "Bearer $($Script:Api.AccessToken)"
    }

    $RequestAttributes = @{
        Headers         = $Headers
        Method          = $Method
        ContentType     = $ContentType
        UseBasicParsing = $true
        Uri             = $Uri
    }

    if ($Body) {
        $RequestAttributes.Body = $Body
    }

    # Retry logic for 429 (Too Many Requests)
    $MaxRetries = 5
    $RetryCount = 0
    $BackoffMilliseconds = 1000  # Start with 1 second

    do {
        # Apply rate limit delay before request
        Invoke-RateLimitDelay -Uri $Uri

        try {
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Making API request (attempt $($RetryCount + 1)/$($MaxRetries + 1)). URI: $Uri, Method: $Method"
            $WebResponse = Invoke-WebRequest @RequestAttributes -ErrorAction Stop

            # Update rate limit state on success
            $RateLimitState = $Script:RateLimit[$Uri.Host]
            $RateLimitState.LastRequestAt = [datetime]::Now
            $RateLimitState.ConsecutiveOks = if ($null -eq $RateLimitState.ConsecutiveOks) { 1 } else { $RateLimitState.ConsecutiveOks + 1 }

            # Extract rate limit headers if available
            if ($WebResponse.Headers['X-Rate-Limit-Remaining']) {
                $RemainingRequests = [int]$WebResponse.Headers['X-Rate-Limit-Remaining']
                $RateLimitCapacity = [int]$WebResponse.Headers['X-Rate-Limit-Limit']
                Write-Debug -Message "$($MyInvocation.MyCommand.Name): Rate limit: $RemainingRequests/$RateLimitCapacity requests remaining"

                # If we're at 20% of limit, increase delay slightly to stay safe
                if ($RemainingRequests -lt ($RateLimitCapacity * 0.2)) {
                    if ($RateLimitState.ConsecutiveOks -gt 10) {
                        # Only increase if we had many consecutive successes
                        $RateLimitState.DelayMilliseconds = [Math]::Max($RateLimitState.DelayMilliseconds, 500)
                    }
                }
                # Decrease delay if we're doing well
                elseif ($RemainingRequests -gt ($RateLimitCapacity * 0.8) -and $RateLimitState.ConsecutiveOks -gt 20) {
                    $RateLimitState.DelayMilliseconds = [Math]::Max(0, $RateLimitState.DelayMilliseconds - 50)
                }
            }

            # Persist updated state
            Save-RateLimitState

            # Parse and cache JSON response
            $ContentType = $WebResponse.Headers.'Content-Type'
            if ($ContentType -like '*json*') {
                $ParsedResponse = $WebResponse.Content | ConvertFrom-Json -Depth 10
                
                # Cache GET responses only (idempotent and safe)
                if ($Method -eq 'Get') {
                    Set-CachedResponse -Uri $Uri.AbsoluteUri -ResponseData $ParsedResponse
                }
                
                return $ParsedResponse
            }
            else {
                # Don't cache non-JSON responses
                return $WebResponse.Content
            }
        }
        catch {
            $StatusCode = $null
            $RetryAfter = $null

            # Extract status code
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $StatusCode = $_.Exception.Response.StatusCode.value__
                Write-Debug -Message "$($MyInvocation.MyCommand.Name): Request failed with HTTP status: $StatusCode"
            }

            # Handle 429 (Too Many Requests) with retry
            if ($StatusCode -eq 429) {
                $RetryCount++

                # Extract Retry-After header if available
                $RetryAfterHeader = $_.Exception.Response.Headers['Retry-After']
                if ($RetryAfterHeader) {
                    $RetryAfter = [int]$RetryAfterHeader
                    Write-Warning "$($MyInvocation.MyCommand.Name): Rate limited (429). Retry-After: ${RetryAfter}s. Retrying in ${RetryAfter}s... (attempt $RetryCount/$MaxRetries)"
                    $DelayMilliseconds = $RetryAfter * 1000
                }
                else {
                    # Use exponential backoff if no Retry-After header
                    $DelayMilliseconds = $BackoffMilliseconds * [Math]::Pow(2, $RetryCount - 1)
                    Write-Warning "$($MyInvocation.MyCommand.Name): Rate limited (429). No Retry-After header. Using exponential backoff. Retrying in ${DelayMilliseconds} milliseconds... (attempt $RetryCount/$MaxRetries)"
                }

                # Update rate limit state with backoff
                $RateLimitState = $Script:RateLimit[$Uri.Host]
                Update-RateLimitOn429 -Uri $Uri -BackoffMilliseconds ([Math]::Max(1000, [int]$DelayMilliseconds))

                # Wait and retry
                Start-Sleep -Milliseconds $DelayMilliseconds

                if ($RetryCount -lt $MaxRetries) {
                    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Retrying after 429."
                    continue
                }
                else {
                    Write-Error "$($MyInvocation.MyCommand.Name): Maximum retry attempts ($MaxRetries) exceeded for 429 error. Giving up."
                    throw $_
                }
            }

            # For other errors, use standard error resolution
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Non-429 error occurred. Status: $statusCode. Delegating to Resolve-ApiError."
            Resolve-ApiError -ErrorRecord $_
        }
    } while ($RetryCount -lt $MaxRetries)
    <#
    .SYNOPSIS
    Invokes an authenticated API request to the Apple Business Manager API with rate limit handling.

    .DESCRIPTION
    Sends an authenticated HTTP request to the Apple Business Manager API with automatic rate limiting, 429 retry logic,
    and response caching. Manages access token generation, renewal, and expiration monitoring. Handles rate limit headers
    dynamically and automatically retries on 429 (Too Many Requests) responses with exponential backoff, extracting
    Retry-After headers when available. Caches GET responses locally to reduce API calls and avoid rate limiting.
    Persists rate limit state across sessions for adaptive rate limit calculation.

    .PARAMETER Uri
    The uniform resource identifier (API endpoint URL) to send the request to. Required.

    .PARAMETER Method
    The HTTP method for the request. Valid values include: Get, Post, Put, Patch, Delete, Head, Options, Trace. Required.

    .PARAMETER Body
    The request body content as a JSON string. Optional. If provided, it will be sent with the specified Content-Type header.

    .PARAMETER ContentType
    The content type of the request body. Default is 'application/json'. Optional.

    .OUTPUTS
    System.Object
    Returns the parsed JSON response from the API as a PowerShell object.

    .EXAMPLE
    $Response = Invoke-ApiRequest -Method Get -Uri 'https://api-business.apple.com/v1/orgDevices'
    Sends an authenticated GET request to retrieve organization devices.

    .EXAMPLE
    $Body = @{ data = @{ type = 'orgDevices'; id = 'device123' } } | ConvertTo-Json
    $Response = Invoke-ApiRequest -Method Post -Uri 'https://api-business.apple.com/v1/orgDeviceActivities' -Body $Body
    Sends an authenticated POST request with a JSON body. Automatically handles rate limiting and retries on 429.

    .NOTES
    This is an internal helper function used by other module cmdlets.
    Requires Apple Business Manager API configuration to be initialized via New-ApiConfig and Import-ApiConfig.

    State & Cache Files:
    - Rate limit state: Configured via $Script:Config.RateLimitStatePath or defaults to .ApiRateLimitState.json in current directory
    - Response cache: Configured via $Script:Config.ResponseCachePath or defaults to .ApiResponseCache.json in current directory
    Both files are hidden (start with .) to prevent accidental git commits.

    Rate Limiting Features:
    - Tracks rate limit state per API host
    - Applies dynamic delays between requests based on rate limit headers
    - Automatically retries on 429 (Too Many Requests) responses
    - Uses exponential backoff or Retry-After headers for retry delays
    - Persists rate limit state to disk for cross-session learning
    - Adaptively adjusts delays based on consecutive success/failure patterns

    Response Caching Features:
    - Automatically caches GET responses locally (1 hour default TTL)
    - Returns cached responses when available, avoiding redundant API calls
    - Significantly reduces rate limit pressure
    - Cache can be cleared manually using Clear-CacheEntry function
    - Only GET requests are cached (POST, PUT, PATCH, DELETE bypass cache)

    The function automatically:
    - Validates configuration is loaded (Key, KeyId, ClientId, TokenUrl, TimeToLive)
    - Checks cache for GET requests and returns cached responses when valid
    - Initializes rate limit state for the API host
    - Manages access token generation and renewal
    - Applies pre-request delays based on learned rate limits
    - Extracts and processes X-Rate-Limit-* response headers
    - Handles 429 responses with automatic retry (up to 5 attempts)
    - Caches successful GET responses to disk
    - Updates rate limit state on success and failure

    .LINK
    Initialize-RateLimitState

    .LINK
    Invoke-RateLimitDelay

    .LINK
    Update-RateLimitOn429

    .LINK
    Save-RateLimitState

    .LINK
    Get-CachedResponse

    .LINK
    Set-CachedResponse

    .LINK
    Clear-CacheEntry

    .LINK
    Update-RateLimitOn429

    .LINK
    Save-RateLimitState
    #>
}