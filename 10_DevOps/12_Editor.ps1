# NOTE: Currently, I consider VS Code almost a requirement for DevOps
if (!$Release) {
    choco upgrade -y vscode-insiders
} else {
    choco upgrade -y vscode
}

@(
    if (!$Release) {
        "ms-vscode.PowerShell-Preview"
    } else {
        "ms-vscode.PowerShell"
    }
) | InstallCodeExtension
