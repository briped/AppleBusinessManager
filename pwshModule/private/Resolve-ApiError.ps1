function Resolve-ApiError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Processing API error. Details: $($ErrorRecord.Exception.Message)"

    # Extract HTTP status code first
    $statusCode = $null
    try {
        if ($ErrorRecord.Exception.Response -and $ErrorRecord.Exception.Response.StatusCode) {
            $statusCode = $ErrorRecord.Exception.Response.StatusCode.value__
        }
    }
    catch {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Could not extract status code"
    }

    # Handle specific status codes
    if ($statusCode -eq 404) {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): 404 error - returning null"
        return $null
    }

    if ($statusCode -eq 429) {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): 429 error encountered - this should have been handled by Invoke-ApiRequest retry logic"
        throw $ErrorRecord
    }

    # Try JSON error response first (standard for Apple Business Manager API)
    if (Test-Json -Json $ErrorRecord.ErrorDetails.Message) {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Error response is JSON format"
        try {
            $ApiError = ($ErrorRecord.ErrorDetails.Message | ConvertFrom-Json -Depth 5).errors[0]
            if ($ApiError.status -eq 404) {
                Write-Debug -Message "$($MyInvocation.MyCommand.Name): JSON 404 error - returning null"
                return $null
            }
            if ($ApiError.status -eq 429) {
                Write-Debug -Message "$($MyInvocation.MyCommand.Name): JSON 429 error - this should have been handled by Invoke-ApiRequest"
                throw $ApiError
            }
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Throwing API error with status: $($ApiError.status)"
            throw $ApiError
        }
        catch {
            # If JSON parsing fails, continue to original error
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): JSON parsing failed, proceeding with original error"
        }
    }

    # Throw the original error if no specific handling was applied
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Throwing original error record"
    throw $ErrorRecord
    <#
    .SYNOPSIS
    Processes API error responses with consistent error handling across functions.

    .DESCRIPTION
    Internal helper function that standardizes error handling for Apple Business Manager API responses.
    Handles both JSON-formatted error responses and HTTP status codes. Returns $null for 404 errors,
    throws detailed error information for other statuses. Delegates 429 errors to Invoke-ApiRequest
    retry logic (should rarely reach this function).

    .PARAMETER ErrorRecord
    The ErrorRecord object from a catch block.

    .OUTPUTS
    System.Object
    Returns $null for 404 errors. For other errors, throws the error.

    .EXAMPLE
    try {
        Invoke-ApiRequest -Method Get -Uri $Uri
    }
    catch {
        Resolve-ApiError -ErrorRecord $_
    }

    .NOTES
    This is an internal helper function used by public functions in the module.
    Implements unified error handling across all API-calling functions.
    429 (Too Many Requests) errors should be handled by Invoke-ApiRequest's retry logic.
    #>
}
