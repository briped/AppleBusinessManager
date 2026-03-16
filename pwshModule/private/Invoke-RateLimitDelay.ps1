function Invoke-RateLimitDelay {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [uri]$Uri
    )

    $RateLimitState = $Script:RateLimit[$Uri.Host]
    if ($RateLimitState.DelayMilliseconds -gt 0 -and $RateLimitState.LastRequestAt) {
        $Elapsed   = ([datetime]::Now - [datetime]$RateLimitState.LastRequestAt).TotalMilliseconds
        $Remaining = $RateLimitState.DelayMilliseconds - $Elapsed
        if ($Remaining -gt 0) {
            Write-Debug "$($MyInvocation.MyCommand.Name): Rate limit delay ${Remaining} milliseconds (learned: $($RateLimitState.DelayMilliseconds) milliseconds)"
            Start-Sleep -Milliseconds $Remaining
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