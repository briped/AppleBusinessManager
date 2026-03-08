New-Variable -Force -Scope Script -Name Config -Value @{}
$Script:Config = @{
    TokenUrl   = [uri]'https://account.apple.com/auth/oauth2/v2/token'
    ApiUrl     = [uri]'https://api-business.apple.com/v1'
    TimeToLive = [timespan]::FromMinutes(15)
}

New-Variable -Force -Scope Script -Name Api -Value @{}

$ExcludeFunctionRegex = [regex]'^\.|\.dev$|\.test$'

$PublicFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'
$PublicFunctions = Get-ChildItem -File -Filter '*.ps1' -Path $PublicFunctionsPath | 
    Where-Object { $_.BaseName -notmatch $ExcludeFunctionRegex }

$PrivateFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath 'private'
$PrivateFunctions = Get-ChildItem -File -Filter '*.ps1' -Path $PrivateFunctionsPath | 
    Where-Object { $_.BaseName -notmatch $ExcludeFunctionRegex }

$Functions = @($PrivateFunctions; $PublicFunctions).Foreach({[System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) + [System.Environment]::NewLine})
. ([System.Management.Automation.ScriptBlock]::Create($Functions))

Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *