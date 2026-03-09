function Update-RateLimitOnSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri
    )

    $rl = $Script:RateLimit[$Uri.Host]
    $rl.ConsecutiveOks++
    if ($rl.DelayMs -gt 0 -and $rl.ConsecutiveOks % 10 -eq 0) {
        $rl.DelayMs = [math]::Max(0, [math]::Floor($rl.DelayMs * 0.75))
        Write-Debug "$($MyInvocation.MyCommand.Name): Relaxing delay to $($rl.DelayMs)ms after $($rl.ConsecutiveOks) clean requests."
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