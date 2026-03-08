$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$ParentDir = ([System.IO.DirectoryInfo]$PSScriptRoot).Parent
$ModuleDir = Join-Path -Path $ParentDir -ChildPath 'pwshModule'
$Module = [System.IO.FileInfo](Join-Path -Path $ModuleDir -ChildPath 'AppleBusinessManager.psm1')
Import-Module -Force -Name $Module
$Data = Import-Clixml -Path (Join-Path -Path $ParentDir -ChildPath '.claimsData.xml')

$Attributes = @{
    Key        = $Data.PrivateKey
    KeyId      = $Data.KeyId
    ClientId   = $Data.ClientId
    TokenUrl   = 'https://account.apple.com/auth/oauth2/v2/token'
    TimeToLive = New-TimeSpan -Minutes 15
}
$Response = Request-AccessToken @Attributes
$Response
$oDev = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Response)"} -Method Get -Uri 'https://api-business.apple.com/v1/orgDevices'