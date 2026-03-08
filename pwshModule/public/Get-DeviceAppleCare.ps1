function Get-DeviceAppleCare {
    [CmdletBinding(DefaultParameterSetName = 'Limit')]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [string]
        $Id
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
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            throw 'All switch is not implemented yet.'
        }
    }
    process {
        $Endpoint = "/orgDevices/${Id}/appleCareCoverage"
        $Uri = [uri]"$($Script:Config.ApiUrl)$($Endpoint)"
        $Attributes = @{
            Method = 'Get'
            Uri = $Uri
        }
        $Response = Invoke-ApiRequest @Attributes
        $Response
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