Set-ExecutionPolicy RemoteSigned
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

@(
    "PackageManagement"
    "PowerShellGet"
) | UpdateModule