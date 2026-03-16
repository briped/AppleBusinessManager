function Get-DeviceActivity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]
        $DeviceId
        ,
        [Parameter()]
        [ValidateSet('status', 'subStatus', 'createdDateTime', 'completedDateTime', 'downloadUrl')]
        [string[]]
        $Fields
        ,
        [Parameter()]
        [switch]
        $Raw
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $QueryString = [System.Web.HttpUtility]::ParseQueryString($null)
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('/orgDeviceActivities'))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString($DeviceId))"
        if ($PSBoundParameters.ContainsKey('Fields')) { $QueryString.Set('fields[orgDevices]', $Fields -join ',') }
        $UriBuilder.Query = $QueryString.ToString()

        try {
            $Response = Invoke-ApiRequest -Method Get -Uri $UriBuilder.Uri
            if ($Raw) { $Response }
            else { $Response.data }
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