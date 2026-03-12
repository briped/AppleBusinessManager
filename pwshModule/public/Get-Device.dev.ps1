function Get-abmDevice {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Id'
                ,  Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [string]
        $DeviceId
        ,
        [Parameter(ParameterSetName = 'ID')]
        [Parameter(ParameterSetName = 'AppleCare')]
        [Switch]
        $AppleCare
        ,
        [Parameter(ParameterSetName = 'ID')]
        [Parameter(ParameterSetName = 'AssignedServer'
                ,  Mandatory = $true)]
        [Switch]
        $AssignedServer
        ,
        [Parameter(ParameterSetName = 'ID')]
        [Parameter(ParameterSetName = 'AssignedServerId'
                ,  Mandatory = $true)]
        [Switch]
        $AssignedServerId
        ,
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'DefaultAll')]
        [Parameter(ParameterSetName = 'ID')]
        [ValidateSet('serialNumber', 'addedToOrgDateTime', 'releasedFromOrgDateTime'
                    ,'updatedDateTime', 'deviceModel', 'productFamily', 'productType'
                    ,'deviceCapacity', 'partNumber', 'orderNumber', 'color', 'status'
                    ,'orderDateTime', 'imei', 'meid', 'eid', 'wifiMacAddress'
                    ,'bluetoothMacAddress', 'ethernetMacAddress', 'purchaseSourceId'
                    ,'purchaseSourceType', 'assignedServer', 'appleCareCoverage')]
        [Parameter(ParameterSetName = 'AppleCare')]
        [ValidateSet('status', 'paymentType', 'description', 'agreementNumber'
                    ,'startDateTime', 'endDateTime', 'isRenewable', 'isCanceled'
                    ,'contractCancelDateTime')]
        [Parameter(ParameterSetName = 'AssignedServer')]
        [ValidateSet('serverName', 'serverType', 'createdDateTime', 'updatedDateTime'
                    ,'devices')]
        [string[]]
        $Fields
        ,
        [Parameter(ParameterSetName = 'ID')]
        [Parameter(ParameterSetName = 'AppleCare')]
        [ValidateRange(1, 1000)]
        [int]
        $Limit
        ,
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'AppleCare')]
        [Switch]
        $All
        ,
        [Parameter()]
        [switch]
        $Raw
    )
    begin {
        Write-Host "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        $PSCmdlet.ParameterSetName
    }
    <#
    .NOTES
	Merging in single function, or at least thinking about it.
    #>
}