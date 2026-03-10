function Get-ServerAssignedDevice {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Id')]
        [string]
        $ServerId
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
    }
    process {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('mdmServers'))"
        if ($PSBoundParameters.ContainsKey('ServerId')) { $UriBuilder.Path += "/$([uri]::EscapeDataString($ServerId))" }
        $UriBuilder.Path += "/$([uri]::EscapeDataString('relationships'))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString('devices'))"
        if ($PSBoundParameters.ContainsKey('Limit')) { $QueryString.Set('limit', $Limit) }
        if ($PSCmdlet.ParameterSetName -eq 'All') { $QueryString.Set('limit', 1000) }
        $UriBuilder.Query = $QueryString.ToString()
        $Uri = $UriBuilder.Uri
        do {
            $Response = Invoke-ApiRequest -Method Get -Uri $Uri
            if ($PSCmdlet.ParameterSetName -eq 'Limit') { return $Response }
            $Uri = $Response.links.next
            $Response.data
        } while ($Uri)
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