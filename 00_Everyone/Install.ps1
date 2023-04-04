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