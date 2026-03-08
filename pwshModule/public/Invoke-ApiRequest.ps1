function Invoke-ApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ApiUrl')]
        [uri]
        $Uri
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method
        ,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Body
        ,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ContentType = 'application/json'
    )
    begin {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    }
    process {
        if (!$Script:access_token) {
            $Response = Request-AccessToken
            $Script:access_token = $Response.access_token
        }
        $Headers = @{
            Authorization = "Bearer $($Script:access_token)"
        }
        $Attributes = @{
            Headers = $Headers
            Method = $Method
            Uri = $Uri
        }
        $Response = Invoke-RestMethod @Attributes
        $Response
    }
    <#
    .SYNOPSIS
    .DESCRIPTION
    .PARAMETER Uri
    .PARAMETER Method
    .PARAMETER Body
    .PARAMETER ContentType
    .NOTES
    #>
}