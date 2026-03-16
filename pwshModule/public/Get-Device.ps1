function Get-Device {
    [CmdletBinding(DefaultParameterSetName = 'NoID')]
    param (
        [Parameter(ParameterSetName = 'ID'
                ,  Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]
        $DeviceId
        ,
        [Parameter()]
        [ValidateSet('serialNumber', 'addedToOrgDateTime', 'releasedFromOrgDateTime'
                    ,'updatedDateTime', 'deviceModel', 'productFamily', 'productType'
                    ,'deviceCapacity', 'partNumber', 'orderNumber', 'color', 'status'
                    ,'orderDateTime', 'imei', 'meid', 'eid', 'wifiMacAddress'
                    ,'bluetoothMacAddress', 'ethernetMacAddress', 'purchaseSourceId'
                    ,'purchaseSourceType', 'assignedServer', 'appleCareCoverage')]
        [string[]]
        $Fields
        ,
        [Parameter(ParameterSetName = 'NoID')]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
        ,
        [Parameter(ParameterSetName = 'NoID')]
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
        $UriBuilder.Path += "/$([uri]::EscapeDataString('orgDevices'))"
        if ($PSBoundParameters.ContainsKey('DeviceId')) { $UriBuilder.Path += "/$([uri]::EscapeDataString($DeviceId))" }
        if ($PSBoundParameters.ContainsKey('Limit')) { $QueryString.Set('limit', $Limit) }
        if ($PSCmdlet.ParameterSetName -eq 'All') { $QueryString.Set('limit', 1000) }
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
        $UriBuilder.Query = $QueryString.ToString()
        $Uri = $UriBuilder.Uri
        do {

            try {
                $Response = Invoke-ApiRequest -Method Get -Uri $UriBuilder.Uri
                if ($PSCmdlet.ParameterSetName -eq 'NoID' -and !$All) {
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
    .NOTES
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-orgdevice-information

Get Device Information
Get information about a device in an organization.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices/{id}
Path Parameters
id
string
(Required) The unique identifier for the resource.
Query Parameters
fields[orgDevices]
[string]
The fields to return for included related types.
Possible Values: serialNumber, addedToOrgDateTime, releasedFromOrgDateTime, updatedDateTime, deviceModel, productFamily, productType, deviceCapacity, partNumber, orderNumber, color, status, orderDateTime, imei, meid, eid, wifiMacAddress, bluetoothMacAddress, ethernetMacAddress, purchaseSourceId, purchaseSourceType, assignedServer, appleCareCoverage

    https://developer.apple.com/documentation/applebusinessmanagerapi/get-org-devices
Get Organization Devices
Get a list of devices in an organization that enroll using Automated Device Enrollment.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices
Query Parameters
fields[orgDevices]
[string]
The fields to return for included related types.
Possible Values: serialNumber, addedToOrgDateTime, releasedFromOrgDateTime, updatedDateTime, deviceModel, productFamily, productType, deviceCapacity, partNumber, orderNumber, color, status, orderDateTime, imei, meid, eid, wifiMacAddress, bluetoothMacAddress, ethernetMacAddress, purchaseSourceId, purchaseSourceType, assignedServer, appleCareCoverage
limit
integer
The number of included related resources to return.
Maximum: 1000
    #>
}