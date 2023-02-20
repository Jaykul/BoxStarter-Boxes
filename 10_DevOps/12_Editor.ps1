# NOTE: Currently, I consider VS Code almost a requirement for DevOps
if ($Insider) {
    choco upgrade -y vscode-insiders
} else {
    choco upgrade -y vscode
}

@(
    if ($Insider) {
        "ms-vscode.PowerShell-Preview"
    } else {
        "ms-vscode.PowerShell"
    }
) | InstallCodeExtension
