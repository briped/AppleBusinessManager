function Set-DeviceServer {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Assign', 'Unassign')]
        [string]
        $Action
        ,
        [Parameter(ParameterSetName = 'Assign')]
        [switch]
        $Assign
        ,
        [Parameter(ParameterSetName = 'Unassign')]
        [switch]
        $Unassign
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $ServerId
        ,
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string[]]
        $DeviceId
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): ParameterSet: '$($PSCmdlet.ParameterSetName)'. $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        $Activity = if ($Unassign) { 'UNASSIGN_DEVICES' } else { 'ASSIGN_DEVICES' }
        $Data = @{
            data = @{
                type = 'orgDeviceActivities'
                attributes = @{
                    activityType = $Activity
                }
                relationships = @{
                    mdmServer = @{
                        data = @{
                            type = 'mdmServers'
                            id = $ServerId
                        }
                    }
                    devices = @{}
                }
            }
        }
    }
    process {
        $UriBuilder = [System.UriBuilder]::new($Script:Config.ApiUrl)
        $UriBuilder.Path += "/$([uri]::EscapeDataString('orgDeviceActivities'))"

        $Data.Relationships.devices.data = @()
        foreach ($Id in $DeviceId) {
            $Data.data.relationships.devices.data += @{
                type = 'orgDevices'
                id = $Id
            }
        }
        $Payload = $Data | ConvertTo-Json -Compress -Depth 5
        $Request = @{
            Uri    = $UriBuilder.Uri
            Method = 'POST'
            Body   = $Payload
        }
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Invoke-ApiRequest $($Request | ConvertTo-Json -Compress -Depth 10 -WarningAction SilentlyContinue)"
        try {
            $Response = Invoke-ApiRequest -Method Post -Uri $UriBuilder.Uri -Body $Payload
            if ($Raw) { $Response }
            else { $Response.data }
        }
        catch {
            throw $_
        }
    }
    <#
    .NOTES
    Changing this to separate assign/unassign functions.


https://developer.apple.com/documentation/applebusinessmanagerapi/create-an-orgdeviceactivity

Assign or Unassign Devices to a Device Management Service
Assign or unassign devices to a device management service.
Apple Business Manager API 1.5+
URL
POST https://api-business.apple.com/v1/orgDeviceActivities
HTTP Body
OrgDeviceActivityCreateRequest
Content-Type: application/json

curl -X POST https://api-business.apple.com/v1/orgDeviceActivities \
 -H "Authorization: Bearer ${ACCESS_TOKEN} \
 -d '{
   "data": {
     "type": "orgDeviceActivities",
     "attributes": {
       "activityType": "ASSIGN_DEVICES"
     },
     "relationships": {
       "mdmServer": {
         "data": {
           "type": "mdmServers",
           "id": "1F97349736CF4614A94F624E705841AD"
         }
       },
       "devices": {
         "data": [
           {
             "type": "orgDevices",
             "id": "XABC123X0ABC123X0"
           }
         ]
       }
     }
   }
 }'

#>
}