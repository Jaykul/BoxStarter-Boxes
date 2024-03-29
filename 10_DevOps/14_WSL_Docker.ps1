Import-Module $PSScriptRoot\WSL.psm1
#--- Enable developer mode on the system ---
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

## We don't need Hyper-V for WSL anymore, so I haven't installed it in 2 years
# choco install -y Microsoft-Hyper-V-All --source="'windowsFeatures'"
choco install -y Microsoft-Windows-Subsystem-Linux, Containers --source="'windowsfeatures'"

if (Test-PendingReboot) {
    Invoke-Reboot
}

wsl --update
# NOTE: Other distros can be scripted the same way. See `wsl --list --online`
if (!$WslDistro) { $WslDistro = "Ubuntu" }
if ((wsl --list -q) -notcontains $WslDistro) {
    # NOTE: This triggers the "Insecure" parameter set, and we up with no password
    Install-WslDistro -Distribution $WslDistro -Username $Env:USERNAME.ToLower() -Default
    # Set up npiperelay for this distro so I can use KeeAgent from WSL
    Install-WslKeeAgentPipe -Distribution $WslDistro -Username $Env:USERNAME.ToLower()
}

# BUG: This assumes your distro uses apt...
# Update everything on the default distro
wsl -d $WslDistro -u root apt update
wsl -d $WslDistro -u root apt upgrade -y

RefreshEnv
if (Test-PendingReboot) {
    Write-Warning "Rebooting for docker dependency on containers"
    Invoke-Reboot
}

choco upgrade -y docker-desktop
@(
    "ms-azuretools.vscode-docker"
) | InstallCodeExtension