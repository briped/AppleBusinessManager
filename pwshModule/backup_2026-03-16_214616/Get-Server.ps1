function Get-Server {
    [CmdletBinding(DefaultParameterSetName = 'NoID'
                ,  HelpURI = 'https://developer.apple.com/documentation/applebusinessmanagerapi/get-device-management-services')]
    param (
        [Parameter(ParameterSetName = 'ID'
                ,  Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]
        $ServerId
        ,
        [Parameter(ParameterSetName = 'NoID')]
        [ValidateSet('serverName', 'serverType', 'createdDateTime', 'updatedDateTime', 'devices')]
        [string[]]
        $Fields
        ,
        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
        ,
        [Parameter()]
        [Switch]
        $All
        ,
        [Parameter()]
        [switch]
        $Raw
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): ParameterSet: '$($PSCmdlet.ParameterSetName)'. $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('mdmServers'))"
        if ($ServerId) {
            $UriBuilder.Path += "/$([uri]::EscapeDataString($ServerId))"
            $UriBuilder.Path += "/$([uri]::EscapeDataString('relationships'))"
            $UriBuilder.Path += "/$([uri]::EscapeDataString('devices'))"
        }
        if ($Limit) { $QueryString.Set('limit', $Limit) }
        if ($All) { $QueryString.Set('limit', 1000) }
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[mdmServers]', $Fields -join ',') }
        $UriBuilder.Query = $QueryString.ToString()
        $Uri = $UriBuilder.Uri
        do {


            try {
                $Response = Invoke-ApiRequest -Method Get -Uri $UriBuilder.Uri
                if (!$All) {
                    if ($Raw) { return $Response }
                    else { return $Response.data }
                }
            }
            catch {
                if (Test-Json -Json $_.ErrorDetails.Message) {
                    $ErrorResponse = ($_.ErrorDetails.Message | ConvertFrom-Json -Depth 5).errors[0]
                    switch ($ErrorResponse.status) {
                        404 { return $null }
                        Default { throw $ErrorResponse }
                    }
                }
                throw $_
            }
            $Uri = $Response.links.next
            if ($Raw) { $Response }
            else { $Response.data }
        } while ($Uri)
    }
    <#
    .SYNOPSIS
    Gets device management services (MDM servers) from Apple Business Manager.

    .DESCRIPTION
    Gets a list of device management services in an organization or the device serial numbers assigned to a specific device management service. Without a ServerId, returns all servers in the organization. When a ServerId is specified, returns the device serial numbers assigned to that server.

    .PARAMETER ServerId
    The unique identifier for a specific device management service. When specified, retrieves device serial numbers assigned to that server. Accepts input via pipeline by property name.

    .PARAMETER Fields
    Specifies which server attributes to return in the response. If not specified, all fields are returned.
    
    Valid values include: serverName, serverType, createdDateTime, updatedDateTime, devices

    .PARAMETER Limit
    The maximum number of records to return per request. Valid range is 1-1000. Default behavior uses API's page size.

    .PARAMETER All
    When specified, retrieves all records by automatically handling pagination.

    .PARAMETER Raw
    When specified, returns the complete API response object including metadata and pagination links. Otherwise returns only the data array.

    .OUTPUTS
    System.Object
    When Raw is not specified: Returns array of PSCustomObject with server or device information.
    When Raw is specified: Returns the full API response object with links and metadata.

    .EXAMPLE
    Get-Server
    Gets all device management services in the organization.

    .EXAMPLE
    Get-Server -Limit 50
    Gets the first 50 device management services.

    .EXAMPLE
    Get-Server -All
    Gets all device management services, automatically handling pagination.

    .EXAMPLE
    Get-Server -ServerId 'server123'
    Gets device serial numbers assigned to a specific device management service.

    .EXAMPLE
    Get-Server -ServerId 'server123' -All
    Gets all device serial numbers assigned to a specific server, handling pagination.

    .EXAMPLE
    Get-Server -Fields serverName, serverType -Raw
    Gets servers with specific fields and returns the complete API response.

    .NOTES
    Requires Apple Business Manager API configuration to be initialized via New-ApiConfig and Import-ApiConfig.
    
    This function wraps two API endpoints:
    - GET /v1/mdmServers (list all device management services)
    - GET /v1/mdmServers/{id}/relationships/devices (get device IDs assigned to a server)

    This help documentation was generated by GitHub Copilot (Claude Haiku 4.5).

    .LINK
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-device-management-services

    .LINK
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-all-device-ids-for-a-device-management-service
    #>
}