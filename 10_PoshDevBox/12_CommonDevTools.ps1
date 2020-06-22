# choco upgrade -y vscode
choco upgrade -y vscode-insiders
# choco upgrade -y microsoft-windows-terminal
choco upgrade -y git.install --package-parameters="'/GitOnlyOnPath /WindowsTerminal /NoShellIntegration /SChannel'"
choco upgrade -y putty.install
choco upgrade -y powershell-core
choco upgrade -y powershell-preview
refreshenv
pwsh (Join-Path $PSScriptRoot ..\PoshBox\01_PowerShellSettings.ps1)

@(
    "shan.code-settings-sync"
    "ms-vscode.PowerShell"
) | InstallCodeExtension