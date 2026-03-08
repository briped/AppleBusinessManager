function Get-DeviceAppleCare {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
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
        [Parameter()]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        $Endpoint = "/orgDevices/${Id}/appleCareCoverage"
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