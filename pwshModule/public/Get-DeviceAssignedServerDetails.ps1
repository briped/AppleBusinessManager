function Get-DeviceAssignedServerDetails {
    [CmdletBinding(DefaultParameterSetName = 'Limit')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('DeviceId')]
        [string]
        $Id
        ,
        [Parameter()]
        [ValidateSet('serverName', 'serverType', 'createdDateTime', 'updatedDateTime', 'devices')]
        [string[]]
        $Fields
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $Endpoint = "/orgDevices/${Id}/assignedServer"
        $Uri = [uri]"$($Script:Config.ApiUrl)$($Endpoint)"
        $Attributes = @{
            Method = 'Get'
            Uri = $Uri
        }
        $Response = Invoke-ApiRequest @Attributes
        #TODO: Implement "raw" response, i.e. return the entire object instead of only the data.
        $Response.data
    }
    <#
https://developer.apple.com/documentation/applebusinessmanagerapi/get-the-assigned-device-management-service-information-for-an-orgdevice

Get the Assigned Device Management Service Information for a Device
Get the assigned device management service information for a device.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices/{id}/assignedServer
Path Parameters
id
string
(Required) The unique identifier for the resource.
Query Parameters
fields[mdmServers]
[string]
The fields to return for included related types.
Possible Values: serverName, serverType, createdDateTime, updatedDateTime, devices
#>
}