# Visual studio dependencies (preinstall for reboot detection)
choco upgrade -y chocolatey-dotnetfx.extension
choco upgrade -y chocolatey-visualstudio.extension
choco upgrade -y dotnetfx
choco upgrade -y visualstudio-installer

if (Test-PendingReboot) {
    Write-Warning "Rebooting for VS2022 dependencies"
    Invoke-Reboot
}

choco upgrade -y visualstudio2022enterprise # visualstudio2022community or visualstudio2022professional

# choco upgrade -y visualstudio2022-workload-python
# choco upgrade -y visualstudio2022-workload-node
# choco upgrade -y visualstudio2022-workload-managedgame
# choco upgrade -y visualstudio2022-workload-data
choco upgrade -y visualstudio2022-workload-netcrossplat
# choco upgrade -y visualstudio2022-workload-datascience
choco upgrade -y visualstudio2022-workload-netweb
choco upgrade -y visualstudio2022-workload-azure
# choco upgrade -y visualstudio2022-workload-nativedesktop
# choco upgrade -y visualstudio2022-workload-nativecrossplat
