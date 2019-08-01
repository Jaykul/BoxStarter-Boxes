& (Join-Path $PSScriptRoot ..\PoshBox\InstallMe.ps1)

& (Join-Path $PSScriptRoot 06_DevMode.ps1)
& (Join-Path $PSScriptRoot 07_CommonDevTools.ps1)
& (Join-Path $PSScriptRoot 08_WSL.ps1)

choco install -y powershell-core
refreshenv
pwsh (Join-Path $PSScriptRoot ..\PoshBox\PowerShellSettings.ps1)


Enable-MicrosoftUpdate
Install-WindowsUpdate -AcceptEula
Enable-RemoteDesktop
# Set-StartScreenOptions -EnableBootToDesktop -EnableDesktopBackgroundOnStart -EnableShowStartOnActiveScreen

# This doesn't seem to work anymore
# Install-ChocolateyPinnedTaskBarItem "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
# Install-ChocolateyPinnedTaskBarItem (gcm code, code-insiders -ErrorAction SilentlyContinue | split-path | Split-Path | ls  -Filter Code*.exe | convert-path)
