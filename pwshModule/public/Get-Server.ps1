function Get-Server {
    [CmdletBinding(DefaultParameterSetName = 'Limit')]
    param (
        [Parameter()]
        [ValidateSet('serverName', 'serverType', 'createdDateTime', 'updatedDateTime', 'devices')]
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
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            # TODO: Implement in-function-paging.
            throw 'All switch is not implemented yet.'
        }
        $Endpoint = "/mdmServers"
        $Uri = [uri]"$($Script:Config.ApiUrl)$($Endpoint)"
    }
    process {
        $Attributes = @{
            Method = 'Get'
            Uri = $Uri
        }
        $Response = Invoke-ApiRequest @Attributes
        #TODO: Implement "raw" response, i.e. return the entire object instead of only the data.
        $Response.data
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