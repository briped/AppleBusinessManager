$VerbosePreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'
$ParentDir = ([System.IO.DirectoryInfo]$PSScriptRoot).Parent
$ModuleDir = Join-Path -Path $ParentDir -ChildPath 'pwshModule'
$Module = [System.IO.FileInfo](Join-Path -Path $ModuleDir -ChildPath 'AppleBusinessManager.psm1')
Import-Module -Force -Name $Module
Import-ApiConfig -Path (Join-Path -Path $ParentDir -ChildPath '.config.xml')
