$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$ParentDir = ([System.IO.DirectoryInfo]$PSScriptRoot).Parent
$ModuleDir = Join-Path -Path $ParentDir -ChildPath 'pwshModule'
$Module = [System.IO.FileInfo](Join-Path -Path $ModuleDir -ChildPath 'AppleBusinessManager.psm1')
Import-Module -Force -Name $Module
$Data = Import-Clixml -Path (Join-Path -Path $ParentDir -ChildPath '.claimsData.xml')

$Attributes = @{}
$Attributes.TimeToLive = [timespan]::FromMinutes(15)
$Attributes.TokenUrl = [uri]'https://account.apple.com/auth/oauth2/v2/token'
$Attributes.ApiUrl = [uri]'https://api-business.apple.com/v1'
$Attributes.Key = $Data.PrivateKey
$Attributes.KeyId = $Data.KeyId
$Attributes.ClientId = $Data.ClientId
New-ApiConfig @Attributes
Export-ApiConfig -Path (Join-Path -Path $ParentDir -ChildPath '.config.xml')
