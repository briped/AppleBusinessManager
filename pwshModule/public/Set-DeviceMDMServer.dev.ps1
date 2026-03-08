function Set-DeviceMDMServer {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Assign', 'Unassign')]
        [string]
        $Activity
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $MdmServer
        ,
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Device
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    }
    process {
        $Data = @{
            type = 'orgDeviceActivities'
            attributes = @{
                activityType = 'ASSIGN_DEVICES'
            }
            Relationships = @{
                mdmServer = @{
                    data = @{
                        type = 'mdmServers'
                        id = '1F97349736CF4614A94F624E705841AD'
                    }
                }
                devices = @{
                    data = @(
                        @{
                            type = 'orgDevices'
                            id = 'serialNumber'
                        },
                        @{
                            type = 'orgDevices'
                            id = 'serialNumber'
                        }
                    )
                }
            }
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