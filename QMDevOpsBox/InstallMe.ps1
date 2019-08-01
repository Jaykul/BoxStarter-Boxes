# & (Join-Path $PSScriptRoot ..\PoshDevBox\InstallMe.ps1)

& (Join-Path $PSScriptRoot 09_Azure.ps1)
& (Join-Path $PSScriptRoot 10_CommonOpsTools.ps1)
& (Join-Path $PSScriptRoot 11_visualstudio2019.ps1)
& (Join-Path $PSScriptRoot 12_Docker.ps1)

choco upgrade -y microsoft-teams
choco install -y office365business