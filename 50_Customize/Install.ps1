[CmdletBinding()]
param (
    # Where to install tools, or at least, symlinks to them
    $UserLocalBinFolder = $(if($IsLinux){ "/usr/local/bin" } else { Join-Path $Env:LocalAppData Programs }),

    # Which WSL distro to install
    $WslDistro = "ubuntu",

    # Large, or Extra Large? If you set this you get dev-mode and insider builds of all the things
    [switch]$Insider
)

if ($Boxstarter -and !$PSScriptRoot) {
    Write-Host "Running in Boxstarter, but not checked out. Cloning the repository."

    # If this script is being run DIRECTLy via Boxstarter, we need to clone the rest of the repository
    $tempdir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tempdir | Out-Null
    Push-Location $tempdir

    choco upgrade -y git.install --package-parameters="'/GitOnlyOnPath /WindowsTerminal /NoShellIntegration /SChannel'"
    Write-Host "Cloning BoxStarter-Boxes"
    git clone https://github.com/Jaykul/BoxStarter-Boxes.git Boxes

    & (Convert-Path Boxes\5*\Install.ps1) @PSBoundParameters

    Pop-Location
    Remove-Item $tempdir -Recurse -Force
}

& (Join-Path $PSScriptRoot ..\1*\Install.ps1) @PSBoundParameters

# I'm giving in to the easy way. This way it's easier to customize by deleting the files you don't want
foreach($file in Get-ChildItem $PSScriptRoot -Filter *.ps1 -Exclude Install.ps1) {
    & $file.FullName
}

# Actually customize everything else
choco upgrade -y chezmoi
chezmoi init $Env:USERNAME --apply

Finalize