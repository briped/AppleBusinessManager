function Get-DeviceMDMServer {
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
        $Endpoint = "/orgDevices/${Id}/relationships/assignedServer"
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
https://developer.apple.com/documentation/applebusinessmanagerapi/get-the-assigned-device-management-service-id-for-an-orgdevice

Get the Assigned Device Management Service ID for a Device
Get the assigned device management service ID information for a device.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices/{id}/relationships/assignedServer
Path Parameters
id
string
(Required) The unique identifier for the resource.

#>
}