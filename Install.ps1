<#
    .SYNOPSIS
        Install a simple tools binary from a github release
#>
[CmdletBinding()]
param (
    # Where to install tools, or at least, symlinks to them
    $UserLocalBinFolder = $(if($IsLinux){ "/usr/local/bin" } else { Join-Path $Env:LocalAppData Programs }),

    # Which WSL distro to install
    $WslDistro = "ubuntu",

    # Large, or Extra Large? If you set this you get dev-mode and insider builds of all the things
    [switch]$Release
)

$PSBoundParameters["Insider"] = $Insider = !$Release

Set-StrictMode -off
$ErrorActionPreference = 'Stop'

if (!(Get-Command choco)) {
    Write-Host "Bootstrapping Chocolatey"
    Invoke-Expression (Invoke-RestMethod https://community.chocolatey.org/install.ps1)

    Set-Alias choco (Convert-Path "$Env:ProgramData\Chocolatey\bin\choco.exe")
    Import-module (Convert-Path "$Env:ProgramData\Chocolatey\helpers\chocolateyInstaller.psm1")
}

if ($PSScriptRoot -and -not $Boxstarter) {
    Write-Host "Bootstrapping Boxstarter"

    choco upgrade -y boxstarter

    $Env:PSModulePath += ';' + (Convert-Path "$Env:ProgramData\Boxstarter")

    Import-Module Boxstarter.Chocolatey -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.Bootstrapper -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.Common -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.WinConfig -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global

    Invoke-BoxStarter (Join-Path $PSScriptRoot ..\5*\Install.ps1)
} elseif ($Boxstarter) {
    Write-Host "Running in Boxstarter, skipping bootstrap"

    # If this script is being run via Boxstarter, we need to clone the rest of the repository
    $tempdir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tempdir | Out-Null
    Push-Location $tempdir

    choco upgrade -y git.install --package-parameters="'/GitOnlyOnPath /WindowsTerminal /NoShellIntegration /SChannel'"
    Write-Host "Cloning BoxStarter-Boxes"
    git clone https://github.com/Jaykul/BoxStarter-Boxes.git Boxes

    & (Convert-Path Boxes\5*\Install.ps1) @PSBoundParameters

    Pop-Location
    Remove-Item $tempdir -Recurse -Force
} else {
    Write-Warning "This script is meant to be called from Boxstarter or used from a local copy of my BoxStarter-Boxes repository"
}