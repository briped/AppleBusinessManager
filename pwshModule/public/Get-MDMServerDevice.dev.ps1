function Get-MDMServerDevice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Id
        ,
        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        $Endpoint = "/mdmServers/${Id}/relationships/devices"
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
https://developer.apple.com/documentation/applebusinessmanagerapi/get-all-device-ids-for-a-device-management-service
Get the Device Serial Numbers for a Device Management Service
Get a list of device serial numbers assigned to a device management service.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/mdmServers/{id}/relationships/devices
Path Parameters
id
string
(Required) The unique identifier for the resource.
Query Parameters
limit
integer
The number of included related resources to return.
Maximum: 1000

#>
}