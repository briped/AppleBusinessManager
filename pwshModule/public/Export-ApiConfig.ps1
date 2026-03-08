function Export-ApiConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $Path
    )
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    $Script:Config | Export-Clixml -Path $Path
    <#
    .SYNOPSIS
    Export API configuration.

    .DESCRIPTION
    Exports the API configuration to a CliXML file.

    .PARAMETER Path
    The filepath to the CliXML file containing the configuration.
    #>
}