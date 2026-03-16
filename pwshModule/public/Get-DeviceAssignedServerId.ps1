function Get-DeviceAssignedServerId {
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
        [switch]
        $Raw
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('orgDevices'))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString($DeviceId))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString('relationships'))"
        $UriBuilder.Path += "/$([uri]::EscapeDataString('assignedServer'))"
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
    WHAT IS THE POINT OF THIS!?
    * /orgDevices/{id}/relationships/assignedServer
        This endpoint queries a single device, for its associated/assigned mdm servers.
        The enpoint returns ONLY the object type (mdmServers) and the associated/assigned mdmServer id.

    * /orgDevices/{id}/assignedServer
        This endpoint queries a single device, for its associated/assigned mdm servers.
        The endpoint returns more details

https://developer.apple.com/documentation/applebusinessmanagerapi/get-the-assigned-device-management-service-id-for-an-orgdevice

Get the Assigned Device Management Service ID for a Device
Get the assigned device management service ID information for a device.
Apple Business Manager API 1.5+
URL
GET https://api-business.apple.com/v1/orgDevices/{id}/relationships/assignedServer
Path Parameters
id
string
(Required) The unique identifier for the resource.

#>
}