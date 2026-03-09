function Update-RateLimitOn429 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri,

        [Parameter(Mandatory = $true)]
        [int]$BackoffMs
    )

    $rl = $Script:RateLimit[$Uri.Host]
    $rl.DelayMs        = if ($rl.DelayMs -eq 0) { $BackoffMs } else { $rl.DelayMs * 2 }
    $rl.ConsecutiveOks = 0
    Save-RateLimitState
    <#
    .SYNOPSIS
        Updates rate limit state after receiving a 429 response.
    .DESCRIPTION
        Doubles the learned inter-request delay for the host (or seeds it from BackoffMs
        if no delay has been learned yet), and resets the consecutive success counter.
        Persists the updated state to disk immediately.
    .PARAMETER Uri
        The URI of the API endpoint. The host portion is used to look up the delay state.
    .PARAMETER BackoffMs
        The current backoff value from the retry loop, used to seed DelayMs if it is
        currently zero.
    .NOTES
        Reads and writes $Script:RateLimit. Always calls Save-RateLimitState.
    #>
}