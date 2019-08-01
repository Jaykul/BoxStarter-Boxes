#--- Enable developer mode on the system ---
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

#--- Developer features (Hyper-V and WSL)
choco install -y Microsoft-Hyper-V-All --source="'windowsFeatures'"
choco install -y Microsoft-Windows-Subsystem-Linux --source="'windowsfeatures'"

if (Test-PendingReboot) {
    Invoke-Reboot
}
