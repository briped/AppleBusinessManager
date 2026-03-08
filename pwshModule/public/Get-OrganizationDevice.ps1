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
        ,
        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            throw 'All switch is not implemented yet.'
        }
        $Endpoint = '/orgDevices'
        $Uri = [uri]"$($Script:Config.ApiUrl)$($Endpoint)"
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