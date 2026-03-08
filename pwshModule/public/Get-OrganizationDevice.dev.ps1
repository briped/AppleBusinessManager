function Get-OrganizationDevice {
    [CmdletBinding()]
    param (
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
        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        $Endpoint = '/orgDevices'
        $Uri = [uri]"$($Script:ApiBaseUri)$($Endpoint)"
    }
    process {
        $Attributes = @{
            Method = 'Get'
            Uri = $Uri
        }
        $Response = Invoke-ApiRequest @Attributes
        $Response
    }
    <#
    .NOTES
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