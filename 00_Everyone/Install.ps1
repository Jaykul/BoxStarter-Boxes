Update-ExecutionPolicy RemoteSigned

Write-Host "=== EVERYONE ==="

# Eventually PSResource will be the default, and it's faster, so we'll use it, but only if it's already here
if (Get-Command Install-PSResource -ErrorAction Ignore) {
    Set-PSResourceRepository -Name PSGallery -Trusted
    filter UpdateModule {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory,ValueFromPipeline)]
            [string]$module
        )
        Find-PSResource $module -Type Module | Where-Object {
            -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
        } | Install-PSResource -TrustRepository -AcceptLicense
    }
} else {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-PackageProvider NuGet -MinimumVersion 2.8.5.208 -ForceBootStrap

    filter UpdateModule {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory,ValueFromPipeline)]
            [string]$module
        )
        Find-Module $module | Where-Object {
            -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
        } | Install-Module -SkipPublisherCheck -AllowClobber -RequiredVersion { $_.Version }
    }

    @(
        "PackageManagement"
        "PowerShellGet"
    ) | UpdateModule
}

if ($IsLinux -or $IsMacOs) {
    Write-Warning "Everything in these BoxStarters is Windows-only."
    exit
}

TZUTIL /s "Eastern Standard Time"

Import-Module (Join-Path $PSScriptRoot PoshBox.psm1) -Force -Scope Global

Write-Host "=== EVERYONE ==="

# I'm giving in to the easy way. This way it's easier to customize by deleting the files you don't want
foreach($file in Get-ChildItem $PSScriptRoot -Filter *.ps1 -Exclude Install.ps1) {
    & $file.FullName
}

Finalize