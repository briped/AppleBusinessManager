function Get-DeviceMDMServerDetails {
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
    }
    process {
        $Endpoint = "/orgDevices/${Id}/assignedServer"
        $Uri = [uri]"$($Script:Config.ApiUrl)$($Endpoint)"
        $Attributes = @{
            Method = 'Get'
            Uri = $Uri
        }
        $Response = Invoke-ApiRequest @Attributes
        $Response
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