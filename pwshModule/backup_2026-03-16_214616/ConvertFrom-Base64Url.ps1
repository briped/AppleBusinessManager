function ConvertFrom-Base64Url {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  Position = 0)]
        [string]
        $Value
    )
    begin {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin: $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        if ($PSCmdlet.MyInvocation.PipelineLength -gt 0) { Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Process: $($Value | ConvertTo-Json -Compress -WarningAction SilentlyContinue)" }
        $Padding = 4 - ($Value.Length % 4)
        if ($Padding -ne 4) { $Value += '=' * $Padding }
        $Base64 = $Value -replace '-', '+' -replace '_', '/'
        $Bytes = [System.Convert]::FromBase64String($Base64)
        $String = [System.Text.Encoding]::UTF8.GetString($Bytes)
        $String
    }
    <#
    .SYNOPSIS
    Convert a Base64URL encoded string back into a the original string.

    .DESCRIPTION
    This function takes a Base64URL encoded string and decodes it back to the original string.
    https://datatracker.ietf.org/doc/html/rfc4648#section-5

    .PARAMETER Value
    The string to be converted from Base64URL.

    .INPUTS
    System.String
    A Base64URL encoded string to be decoded.

    .OUTPUTS
    System.String
    The decoded Base64URL string.

    .EXAMPLE
    ConvertFrom-Base64Url -Value 'VGhpcyBlcXVhdGlvbiBpcyBuZWl0aGVyIHVybCBvciBmaWxlc2FmZTogM14zKzUqMj0xMA'

    Output:
    This equation is neither url or filesafe: 3^3+5*2=10

    .EXAMPLE
    'VGhpcyBlcXVhdGlvbiBpcyBuZWl0aGVyIHVybCBvciBmaWxlc2FmZTogM14zKzUqMj0xMA' | ConvertFrom-Base64Url

    Output:
    This equation is neither url or filesafe: 3^3+5*2=10
    #>
}
