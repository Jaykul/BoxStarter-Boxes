Import-Module (Join-Path $PSScriptRoot ..\PoshBox.psm1) -Force
& (Join-Path $PSScriptRoot ..\10_PoshDevBox\10_ReadMe.ps1)

& (Join-Path $PSScriptRoot 21_Azure.ps1)
& (Join-Path $PSScriptRoot 22_CommonOpsTools.ps1)
& (Join-Path $PSScriptRoot 23_VisualStudio2019.ps1)
& (Join-Path $PSScriptRoot 24_Docker.ps1)
& (Join-Path $PSScriptRoot 25_Office.ps1)

Finalize