# Visual studio dependencies (preinstall for reboot detection)

choco upgrade -y chocolatey-visualstudio.extension
choco upgrade -y KB3033929
choco upgrade -y KB2919355
choco upgrade -y KB2999226
choco upgrade -y dotnetfx
choco upgrade -y visualstudio-installer

if (Test-PendingReboot) {
    Write-Warning "Rebooting for VS2019 dependencies"
    Invoke-Reboot
}

choco upgrade -y visualstudio2019enterprise
choco upgrade -y visualstudio2019-workload-netweb 
choco upgrade -y visualstudio2019-workload-netcrossplat
choco upgrade -y visualstudio2019-workload-azure 
