function Get-DeviceAssignedServerDetails {
    [CmdletBinding(DefaultParameterSetName = 'Limit')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Id')]
        [string]
        $DeviceId
        ,
        [Parameter()]
        [ValidateSet('serverName', 'serverType', 'createdDateTime', 'updatedDateTime', 'devices')]
        [string[]]
        $Fields
        ,
        [Parameter()]
        [switch]
        $Raw
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('orgDevices'))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString($DeviceId))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString('assignedServer'))"
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
        $UriBuilder.Query = $QueryString.ToString()
        $Response = Invoke-ApiRequest -Method Get -Uri $UriBuilder.Uri
        if ($Raw) { $Response }
        else { $Response.data }
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