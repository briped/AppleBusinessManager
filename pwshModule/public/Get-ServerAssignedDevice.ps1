function Get-ServerAssignedDevice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('MdmServerId')]
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
            # TODO: Implement in-function-paging.
            throw 'All switch is not implemented yet.'
        }
    }
    process {
        $Endpoint = "/mdmServers/${Id}/relationships/devices"
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