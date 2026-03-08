function Get-DeviceActivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Id
        ,
        [Parameter()]
        [ValidateSet('status', 'subStatus', 'createdDateTime', 'completedDateTime', 'downloadUrl')]
        [string[]]
        $Fields
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        $Endpoint = "/orgDeviceActivities/${Id}"
        $Uri = [uri]"$($Script:Config.ApiUrl)$($Endpoint)"
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
    .NOTES
    https://developer.apple.com/documentation/applebusinessmanagerapi/get-orgdeviceactivity-information

Get Organization Device Activity Information
Get information for an organization device activity that a device management action, such as assign or unassign, creates.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDeviceActivities/{id}
Path Parameters
id
string
(Required) The unique identifier for the resource.
Query Parameters
fields[orgDeviceActivities]
[string]
The fields to return for included related types.
Possible Values: status, subStatus, createdDateTime, completedDateTime, downloadUrl
    #>
}