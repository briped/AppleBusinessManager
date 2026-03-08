$Script:ApiBaseUri = [uri]'https://api-business.apple.com/v1'
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