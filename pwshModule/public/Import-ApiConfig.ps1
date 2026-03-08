function Import-ApiConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('PSPath')]
        [ValidateScript({if (!(Test-Path -PathType Leaf -Path $_)) { 
            throw "Path '$($_.FullName)' could not be found or it is not a file." }; $true})]
        [System.IO.FileInfo]
        $Path
        ,
        [Parameter()]
        [switch]
        $PassThru
    )
    Write-Debug -Message "$($MyInvocation.MyCommand.Name): $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    $Script:Config = Import-Clixml -Path $Path
    if ($PassThru) { $Script:Config }
    <#
    .SYNOPSIS
    Import API configuration.

    .DESCRIPTION
    Imports the API configuration from a CliXML file.

    .PARAMETER Path
    The filepath to the CliXML file containing the configuration.

    .PARAMETER PassThru
    Returns the imported configuration.

    .NOTES
    #>
}