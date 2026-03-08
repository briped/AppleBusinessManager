function ConvertTo-Base64Url {
    [CmdletBinding(DefaultParameterSetName = 'String')]
    param(
        [Parameter(ParameterSetName = 'String'
                ,  Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  Position = 0)]
        [string]
        $String
        ,
        [Parameter(ParameterSetName = 'Bytes'
                ,  Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  Position = 0)]
        [byte[]]
        $Bytes
    )
    begin {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin: $($PSCmdlet.MyInvocation.BoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
    }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'String') { $Bytes = [System.Text.Encoding]::UTF8.GetBytes(([string]$String)) }
        #$Bytes = if ($Value -is [byte[]]) { $Value } else { [System.Text.Encoding]::UTF8.GetBytes(([string]$Value)) }
        $Base64 = [Convert]::ToBase64String($Bytes)
        $Base64URL = $Base64 -replace '\+', '-' -replace '/', '_' -replace '=+$', ''
        $Base64URL
    }
    <#
    .SYNOPSIS
    Convert a string or byte array to Base64URL encoded string.

    .DESCRIPTION
    This function takes a string or byte array and base64 encodes it to be safely used in URLs, as outlined in RFC4648 section 5.
    https://datatracker.ietf.org/doc/html/rfc4648#section-5

    .PARAMETER Value
    The string or byte array to be converted to Base64URL.

    .INPUTS
    System.String
    A string to be converted to Base64URL encoding.

    System.Byte[]
    A byte array to be converted to Base64URL encoding.

    .OUTPUTS
    System.String
    A Base64URL encoded string.

    .EXAMPLE
    ConvertTo-Base64Url -Value 'This equation is neither url or filesafe: 3^3+5*2=10'

    Output:
    VGhpcyBlcXVhdGlvbiBpcyBuZWl0aGVyIHVybCBvciBmaWxlc2FmZTogM14zKzUqMj0xMA

    This example demonstrates converting a string containing special URL-unsafe characters to Base64URL encoding.

    .EXAMPLE
    'This equation is neither url or filesafe: 3^3+5*2=10' | ConvertTo-Base64Url

    Output:
    VGhpcyBlcXVhdGlvbiBpcyBuZWl0aGVyIHVybCBvciBmaWxlc2FmZTogM14zKzUqMj0xMA

    This example demonstrates piping a string to ConvertTo-Base64Url for encoding.
    #>
}
