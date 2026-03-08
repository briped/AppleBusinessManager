function Get-MDMServer {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('serverName', 'serverType', 'createdDateTime', 'updatedDateTime', 'devices')]
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
        $Endpoint = "/mdmServers"
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
https://developer.apple.com/documentation/applebusinessmanagerapi/get-device-management-services

Get Device Management Services
Get a list of device management services in an organization.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/mdmServers
Query Parameters
fields[mdmServers]
[string]
The fields to return for included related types.
Possible Values: serverName, serverType, createdDateTime, updatedDateTime, devices
limit
integer
The number of included related resources to return.
Maximum: 1000
#>
}