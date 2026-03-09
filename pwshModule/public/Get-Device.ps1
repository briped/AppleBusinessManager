function Get-Device {
    [CmdletBinding(DefaultParameterSetName = 'Limit')]
    param (
        [Parameter(ParameterSetName = 'ID'
                ,  Mandatory = $true)]
        [Alias('DeviceId')]
        [string]
        $Id
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
        [Parameter(ParameterSetName = 'Limit')]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
        ,
        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $Endpoint = "/orgDevices"
    }
    process {
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += $Endpoint
        if ($PSBoundParameters.ContainsKey('Id')) { $UriBuilder.Path += "/$([uri]::EscapeDataString($Id))" }
        if ($PSBoundParameters.ContainsKey('Limit')) { $QueryString.Set('limit', $Limit) }
        if ($PSCmdlet.ParameterSetName -eq 'All') { $QueryString.Set('limit', 1000) }
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
        $UriBuilder.Query = $QueryString.ToString()
        $Uri = $UriBuilder.Uri

        do {
            $Response = Invoke-ApiRequest -Method Get -Uri $Uri
            if ($PSCmdlet.ParameterSetName -eq 'Limit') { return $Response }
            $Uri = $Response.links.next
            $Response.data
        } while ($Uri)
    }
    <#
    .NOTES
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-orgdevice-information

Get Device Information
Get information about a device in an organization.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices/{id}
Path Parameters
id
string
(Required) The unique identifier for the resource.
Query Parameters
fields[orgDevices]
[string]
The fields to return for included related types.
Possible Values: serialNumber, addedToOrgDateTime, releasedFromOrgDateTime, updatedDateTime, deviceModel, productFamily, productType, deviceCapacity, partNumber, orderNumber, color, status, orderDateTime, imei, meid, eid, wifiMacAddress, bluetoothMacAddress, ethernetMacAddress, purchaseSourceId, purchaseSourceType, assignedServer, appleCareCoverage

    https://developer.apple.com/documentation/applebusinessmanagerapi/get-org-devices
Get Organization Devices
Get a list of devices in an organization that enroll using Automated Device Enrollment.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices
Query Parameters
fields[orgDevices]
[string]
The fields to return for included related types.
Possible Values: serialNumber, addedToOrgDateTime, releasedFromOrgDateTime, updatedDateTime, deviceModel, productFamily, productType, deviceCapacity, partNumber, orderNumber, color, status, orderDateTime, imei, meid, eid, wifiMacAddress, bluetoothMacAddress, ethernetMacAddress, purchaseSourceId, purchaseSourceType, assignedServer, appleCareCoverage
limit
integer
The number of included related resources to return.
Maximum: 1000
    #>
}