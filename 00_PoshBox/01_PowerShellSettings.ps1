Set-ExecutionPolicy RemoteSigned
Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -ForceBootStrap
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

@(
    "PackageManagement"
    "PowerShellGet"
) | UpdateModule