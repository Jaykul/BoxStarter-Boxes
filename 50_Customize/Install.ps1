[CmdletBinding()]
param (
    # Where to install tools, or at least, symlinks to them
    $UserLocalBinFolder = $(if($IsLinux){ "/usr/local/bin" } else { Join-Path $Env:LocalAppData Programs }),

    # Which WSL distro to install
    $WslDistro = "ubuntu",

    # Large, or Extra Large? If you set this you get dev-mode and insider builds of all the things
    [switch]$Insider
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
chezmoi init $Env:USERNAME --apply

Finalize