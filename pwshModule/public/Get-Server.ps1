function Get-Server {
    [CmdletBinding(DefaultParameterSetName = 'NoID')]
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
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
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