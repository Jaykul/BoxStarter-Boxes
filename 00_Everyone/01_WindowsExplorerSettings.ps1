# Restores things to the left pane like recycle bin
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1
#--- Windows Taskbar options
# main taskbar AND taskbar where window is open for multi-monitor
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MMTaskbarMode -Value 1
# Hide the search button and bar:
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0
# Hide cortana
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowCortanaButton -Value 0

# Run these last, because the explorer restart will make the other options take effect
# Since they depend on BoxStarter, make them conditional
if (Get-Command Set-StartScreenOptions) {
    Set-StartScreenOptions -EnableShowStartOnActiveScreen
    Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableExpandToOpenFolder -EnableOpenFileExplorerToQuickAccess
} else {
    Write-Warning "BoxStarter not installed. Skipping Explorer options"
}
