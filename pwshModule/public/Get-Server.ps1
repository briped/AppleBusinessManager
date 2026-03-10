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
    }
    process {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('mdmServers'))"
        if ($PSBoundParameters.ContainsKey('Limit')) { $QueryString.Set('limit', $Limit) }
        if ($PSCmdlet.ParameterSetName -eq 'All') { $QueryString.Set('limit', 1000) }
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
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