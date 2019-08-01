# choco upgrade -y vscode
choco upgrade -y vscode-insiders
choco upgrade -y microsoft-windows-terminal
choco upgrade -y git.install --package-parameters="'/GitOnlyOnPath /WindowsTerminal /NoShellIntegration /SChannel'"
choco upgrade -y putty.install
choco install -y powershell-core
refreshenv
pwsh (Join-Path $PSScriptRoot ..\PoshBox\PowerShellSettings.ps1)

@(
    "shan.code-settings-sync"
    "ms-vscode.PowerShell"
) | InstallCodeExtension