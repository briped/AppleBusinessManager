function ConvertTo-ApiQueryString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ResourceType,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]
        $Limit,

        [Parameter(Mandatory = $false)]
        [switch]
        $All,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Fields
    )

    Write-Debug -Message "$($MyInvocation.MyCommand.Name): Building query string. ResourceType: $ResourceType, Limit: $Limit, All: $All, Fields: $($Fields -join ',')"

    $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)

    if ($PSBoundParameters.ContainsKey('Limit')) {
        $QueryString.Set('limit', $Limit)
    }

    if ($All) {
        $QueryString.Set('limit', 1000)
    }

    if ($PSBoundParameters.ContainsKey('Fields') -and $Fields.Count -gt 0) {
        $QueryString.Set("fields[$ResourceType]", $Fields -join ',')
    }

    $QueryString.ToString()
    <#
    .SYNOPSIS
    Constructs an API query string with limit, fields, and pagination parameters.

    .DESCRIPTION
    Internal helper function that standardizes query string construction across Get-* functions.
    Handles limit, All flag, and fields parameters consistently.

    .PARAMETER ResourceType
    The API resource type name used for the fields parameter (e.g., 'orgDevices', 'mdmServers').

    .PARAMETER Limit
    Optional limit parameter value (1-1000).

    .PARAMETER All
    Switch to set limit to 1000 for retrieving all records.

    .PARAMETER Fields
    Optional array of field names to include in the response.

    .OUTPUTS
    System.String
    Returns the formatted query string.

    .EXAMPLE
    $qs = ConvertTo-ApiQueryString -ResourceType 'orgDevices' -Limit 50
    Returns: 'limit=50'

    .EXAMPLE
    $qs = ConvertTo-ApiQueryString -ResourceType 'orgDevices' -Fields @('serialNumber', 'status')
    Returns: 'fields[orgDevices]=serialNumber,status'

    .NOTES
    This is an internal helper function used by public functions in the module.
    #>
}
