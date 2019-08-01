Enable-WindowsOptionalFeature -Online -FeatureName containers -All
RefreshEnv
if (Test-PendingReboot) {
    Write-Warning "Rebooting for docker dependency on containers"
    Invoke-Reboot
}
choco upgrade -y docker-for-windows

InstallCodeExtension "ms-azuretools.vscode-docker"