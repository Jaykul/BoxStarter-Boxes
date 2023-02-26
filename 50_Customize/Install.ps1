<#
    .SYNOPSIS
        Customize my Windows installation with my personal preferences
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

& (Join-Path $PSScriptRoot ..\1*\Install.ps1) @PSBoundParameters

Write-Host "=== CUSTOMIZING ==="

# I'm giving in to the easy way. This way it's easier to customize by deleting the files you don't want
foreach ($file in Get-ChildItem $PSScriptRoot -Filter "??_*.ps1") {
    Write-Host "=== $($file.Name) ==="
    & $file.FullName
}

# Actually customize everything else
choco upgrade -y chezmoi

Start-Sleep 2
Write-Host "In a new PowerShell session, run: chezmoi init $Env:USERNAME --apply"
# chezmoi init $Env:USERNAME --apply

Finalize