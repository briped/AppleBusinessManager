function Save-RateLimitState {
    [CmdletBinding()]
    param()

    try {
        $Script:RateLimit | ConvertTo-Json -Depth 5 |
            Set-Content -Path $Script:RateLimitStateFile -Encoding UTF8
        Write-Debug "$($MyInvocation.MyCommand.Name): Saved to $($Script:RateLimitStateFile)"
    } catch {
        Write-Warning "$($MyInvocation.MyCommand.Name): Could not persist state: $_"
    }
    <#
    .SYNOPSIS
        Persists the current rate limit state to disk.
    .DESCRIPTION
        Serializes $Script:RateLimit to JSON and writes it to $Script:RateLimitStateFile.
        Called whenever the learned delay changes, ensuring state survives between sessions.
    .NOTES
        Writes to $Script:RateLimitStateFile. Failures are non-terminating warnings.
    #>
}