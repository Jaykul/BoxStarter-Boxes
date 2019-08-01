Import-Module (Join-Path $PSScriptRoot ..\PoshBox.psm1) -Force
& (Join-Path $PSScriptRoot ..\00_PoshBox\00_ReadMe.ps1)

& (Join-Path $PSScriptRoot 11_DevMode.ps1)
& (Join-Path $PSScriptRoot 12_CommonDevTools.ps1)
& (Join-Path $PSScriptRoot 13_WSL.ps1)

Finalize