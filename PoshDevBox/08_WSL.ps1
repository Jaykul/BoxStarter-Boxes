choco install -y Microsoft-Hyper-V-All --source="'windowsFeatures'"
choco install -y Microsoft-Windows-Subsystem-Linux --source="'windowsfeatures'"

if (Test-PendingReboot) {
    Invoke-Reboot
}

#--- Ubuntu ---
# TODO: Move this to choco upgrade once --root is included in that package
if (-not (Test-Path ~/Ubuntu.appx)) {
    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~/Ubuntu.appx -UseBasicParsing
}
Add-AppxPackage -Path ~/Ubuntu.appx
RefreshEnv

# run the distro once and have it install locally with root user, unset password
Ubuntu1804 install --root
Ubuntu1804 run apt update
Ubuntu1804 run apt upgrade -y

<#
# We can pre-install tools in the WSL instance
write-host "Installing tools inside the WSL distro..."
Ubuntu1804 run apt install ansible -y
Ubuntu1804 run apt install nodejs -y
#>

<#
# NOTE: Other distros can be scripted the same way for example:

#--- SLES ---
# Install SLES Store app
Invoke-WebRequest -Uri https://aka.ms/wsl-sles-12 -OutFile ~/SLES.appx -UseBasicParsing
Add-AppxPackage -Path ~/SLES.appx
# Launch SLES
sles-12.exe

# --- openSUSE ---
Invoke-WebRequest -Uri https://aka.ms/wsl-opensuse-42 -OutFile ~/openSUSE.appx -UseBasicParsing
Add-AppxPackage -Path ~/openSUSE.appx
# Launch openSUSE
opensuse-42.exe
#>

