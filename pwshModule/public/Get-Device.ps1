function Get-Device {
    [CmdletBinding(DefaultParameterSetName = 'NoID'
                ,  HelpURI = 'https://developer.apple.com/documentation/applebusinessmanagerapi/get-orgdevice-information')]
    param (
        [Parameter(ParameterSetName = 'ID'
                ,  Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]
        $DeviceId
        ,
        [Parameter()]
        [ValidateSet('serialNumber', 'addedToOrgDateTime', 'releasedFromOrgDateTime'
                    ,'updatedDateTime', 'deviceModel', 'productFamily', 'productType'
                    ,'deviceCapacity', 'partNumber', 'orderNumber', 'color', 'status'
                    ,'orderDateTime', 'imei', 'meid', 'eid', 'wifiMacAddress'
                    ,'bluetoothMacAddress', 'ethernetMacAddress', 'purchaseSourceId'
                    ,'purchaseSourceType', 'assignedServer', 'appleCareCoverage')]
        [string[]]
        $Fields
        ,
        [Parameter(ParameterSetName = 'NoID')]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
        ,
        [Parameter(ParameterSetName = 'NoID')]
        [Switch]
        $All
        ,
        [Parameter()]
        [switch]
        $Raw
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): ParameterSet: '$($PSCmdlet.ParameterSetName)'. $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('orgDevices'))"
        if ($PSBoundParameters.ContainsKey('DeviceId')) { $UriBuilder.Path += "/$([uri]::EscapeDataString($DeviceId))" }
        if ($PSBoundParameters.ContainsKey('Limit')) { $QueryString.Set('limit', $Limit) }
        if ($PSCmdlet.ParameterSetName -eq 'All') { $QueryString.Set('limit', 1000) }
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
        $UriBuilder.Query = $QueryString.ToString()
        $Uri = $UriBuilder.Uri
        do {
            try {
                $Response = Invoke-ApiRequest -Method Get -Uri $UriBuilder.Uri
                if ($PSCmdlet.ParameterSetName -eq 'NoID' -and !$All) {
                    if ($Raw) { return $Response }
                    else { return $Response.data }
                }
            }
            catch {
                switch ($_.Exception.StatusCode.value__) {
                    401 {
                        #TODO: Re-authenticate using stored credentials and retry the request once authenticated before throwing an error.
                        throw 'Unauthorized: Access token is missing or invalid. Please authenticate using Get-ApiToken.'
                    }
                    404 { return $null }
                    429 {
                        #$RetryAfter = $_.Exception.Response.Headers['Retry-After']
                        #throw "Too Many Requests: Rate limit exceeded. Please retry after $RetryAfter seconds."
                    }
                    Default {
                        $_
                        return
                    }
                }
            }
            $Uri = $Response.links.next
            if ($Raw) { $Response }
            else { $Response.data }
        } while ($Uri)
    }
    <#
    .SYNOPSIS
    Gets information about devices in Apple Business Manager.

    .DESCRIPTION
    Gets a list of devices or information about a specific device in an Apple Business Manager organization that enroll using Automated Device Enrollment. The function supports pagination and field filtering.

    .PARAMETER DeviceId
    The unique identifier for a specific device. When specified, retrieves detailed information about that device. Accepts input via pipeline by property name.

    .PARAMETER Fields
    Specifies which device attributes to return in the response. If not specified, all fields are returned.
    
    Valid values include: serialNumber, addedToOrgDateTime, releasedFromOrgDateTime, updatedDateTime, deviceModel, productFamily, productType, deviceCapacity, partNumber, orderNumber, color, status, orderDateTime, imei, meid, eid, wifiMacAddress, bluetoothMacAddress, ethernetMacAddress, purchaseSourceId, purchaseSourceType, assignedServer, appleCareCoverage

    .PARAMETER Limit
    The maximum number of devices to return per request. Valid range is 1-1000. Only applies when DeviceId is not specified. Default behavior uses API's page size.

    .PARAMETER All
    When specified, retrieves all devices by automatically handling pagination. Only applies when DeviceId is not specified.

    .PARAMETER Raw
    When specified, returns the complete API response object including metadata and pagination links. Otherwise returns only the device data array.

    .OUTPUTS
    System.Object
    When Raw is not specified: Returns array of PSCustomObject with device information.
    When Raw is specified: Returns the full API response object with links and metadata.

    .EXAMPLE
    Get-Device -DeviceId 'abc123'
    Gets detailed information about a specific device by its ID.

    .EXAMPLE
    Get-Device -Limit 50
    Gets the first 50 devices in the organization.

    .EXAMPLE
    Get-Device -All
    Gets all devices in the organization, automatically handling pagination.

    .EXAMPLE
    Get-Device -DeviceId 'abc123' -Fields serialNumber, deviceModel, status
    Gets specific fields for a device.

    .EXAMPLE
    Get-Device -All -Raw
    Gets all devices and returns the complete API response with pagination metadata.

    .NOTES
    Requires Apple Business Manager API configuration to be initialized via New-ApiConfig and Import-ApiConfig.

    This function wraps two API endpoints:
    - GET /v1/orgDevices (list all devices with optional pagination)
    - GET /v1/orgDevices/{id} (get specific device information)

    This help documentation was generated by GitHub Copilot (Claude Haiku 4.5).

    .LINK
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-orgdevice-information

    .LINK
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-org-devices
    #>
}