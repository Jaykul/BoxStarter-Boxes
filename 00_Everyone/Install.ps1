<#
    .SYNOPSIS
        Basic configuration I apply to all my family computers
#>
[CmdletBinding()]
param (
    # Where to install tools, or at least, symlinks to them
    $UserLocalBinFolder = $(if($IsLinux){ "/usr/local/bin" } else { Join-Path $Env:LocalAppData Programs }),

    # Which WSL distro to install
    $WslDistro = "ubuntu",

    # Large, or Extra Large? If you don't set this you get dev-mode and insider builds of all the things
    [switch]$Release
)

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

# I'm giving in to the easy way. This way it's easier to customize by deleting the files you don't want
foreach ($file in Get-ChildItem $PSScriptRoot -Filter "??_*.ps1") {
    Write-Host "=== $($file.Name) ==="
    & $file.FullName
}

Finalize