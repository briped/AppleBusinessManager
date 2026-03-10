function Get-DeviceAppleCare {
    [CmdletBinding(DefaultParameterSetName = 'Limit')]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]
        $DeviceId
        ,
        [Parameter()]
        [ValidateSet('status', 'paymentType', 'description', 'agreementNumber'
                    ,'startDateTime', 'endDateTime', 'isRenewable', 'isCanceled'
                    ,'contractCancelDateTime')]
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
        $UriBuilder.Path += "/$([uri]::EscapeDataString('orgDevices'))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString($DeviceId))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString('appleCareCoverage'))"
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
https://developer.apple.com/documentation/applebusinessmanagerapi/get-all-apple-care-coverage-for-an-orgdevice

Get AppleCare Coverage Information for a Device
Get a list of AppleCare Coverage resources for an organization device.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices/{id}/appleCareCoverage
Path Parameters
id
string
(Required) The unique identifier for the resource. For example, the device’s serial number.
Query Parameters
fields[appleCareCoverage]
[string]
The fields to return for included related types.
Possible Values: status, paymentType, description, agreementNumber, startDateTime, endDateTime, isRenewable, isCanceled, contractCancelDateTime
limit
integer
The number of included related resources to return.
Maximum: 1000
#>
}