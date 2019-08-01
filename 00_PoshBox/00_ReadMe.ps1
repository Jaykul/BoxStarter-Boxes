TZUTIL /s "Eastern Standard Time"
Import-Module (Join-Path $PSScriptRoot ..\PoshBox.psm1) -Force

& (Join-Path $PSScriptRoot 01_PowerShellSettings.ps1)
& (Join-Path $PSScriptRoot 02_ExplorerSettings.ps1)
& (Join-Path $PSScriptRoot 03_RemoveDefaultApps.ps1)
& (Join-Path $PSScriptRoot 04_CommonUtilities.ps1)
& (Join-Path $PSScriptRoot 05_Browsers.ps1)

Finalize