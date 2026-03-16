function Update-RateLimitOnSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri
    )

    $RateLimitState = $Script:RateLimit[$Uri.Host]
    $RateLimitState.ConsecutiveOks++
    if ($RateLimitState.DelayMilliseconds -gt 0 -and $RateLimitState.ConsecutiveOks % 10 -eq 0) {
        $RateLimitState.DelayMilliseconds = [math]::Max(0, [math]::Floor($RateLimitState.DelayMilliseconds * 0.75))
        Write-Debug "$($MyInvocation.MyCommand.Name): Relaxing delay to $($RateLimitState.DelayMilliseconds) milliseconds after $($RateLimitState.ConsecutiveOks) clean requests."
        Save-RateLimitState
    }
    <#
    .SYNOPSIS
        Updates rate limit state after a successful API response.
    .DESCRIPTION
        Increments the consecutive success counter for the host. Every 10 successful
        requests, reduces the learned delay by 25% (floor), converging back toward
        zero over time. Persists state to disk when the delay changes.
    .PARAMETER Uri
        The URI of the API endpoint. The host portion is used to look up the delay state.
    .NOTES
        Reads and writes $Script:RateLimit. Calls Save-RateLimitState when delay is updated.
    #>
}