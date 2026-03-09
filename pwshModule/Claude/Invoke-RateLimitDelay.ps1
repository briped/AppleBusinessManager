function Invoke-RateLimitDelay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri
    )

    $rl = $Script:RateLimit[$Uri.Host]
    if ($rl.DelayMs -gt 0 -and $rl.LastRequestAt) {
        $elapsed   = ([datetime]::Now - [datetime]$rl.LastRequestAt).TotalMilliseconds
        $remaining = $rl.DelayMs - $elapsed
        if ($remaining -gt 0) {
            Write-Debug "$($MyInvocation.MyCommand.Name): Rate limit delay ${remaining}ms (learned: $($rl.DelayMs)ms)"
            Start-Sleep -Milliseconds $remaining
        }
    }
    <#
    .SYNOPSIS
        Applies an adaptive inter-request delay for a given API host.
    .DESCRIPTION
        Calculates how much of the learned delay period has already elapsed since the
        last request, and sleeps only for the remaining portion. Has no effect if no
        delay has been learned yet or if enough time has already passed.
    .PARAMETER Uri
        The URI of the API endpoint. The host portion is used to look up the delay state.
    .NOTES
        Reads from $Script:RateLimit, which must be initialized by Initialize-RateLimitState.
    #>
}