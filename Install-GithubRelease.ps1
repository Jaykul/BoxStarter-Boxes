<#
    .DESCRIPTION
        A cross-platform script to download, check the file hash, and make sure the binary is on your PATH.
    .SYNOPSIS
        Install a binary from a github release.
    .EXAMPLE
        Install-GithubRelease FluxCD Flux2

        Install `Flux` from the https://github.com/FluxCD/Flux2 repository
    .EXAMPLE
        Install-GithubRelease earthly earthly

        Install `earthly` from the https://github.com/earthly/earthly repository
    .EXAMPLE
        Install-GithubRelease junegunn fzf

        Install `fzf` from the https://github.com/junegunn/fzf repository
    .EXAMPLE
        Install-GithubRelease BurntSushi ripgrep

        Install `rg` from the https://github.com/BurntSushi/ripgrep repository
    .EXAMPLE
        Install-GithubRelease opentofu opentofu

        Install `opentofu` from the https://github.com/opentofu/opentofu repository
    .EXAMPLE
        Install-GithubRelease twpayne chezmoi

        Install `chezmoi` from the https://github.com/twpayne/chezmoi repository
    .EXAMPLE
        Install-GithubRelease sharkdp bat
        Install-GithubRelease sharkdp fd

        Install `bat` and `fd` from their repositories
    .NOTES
        All these examples are (only) tested on Windows and WSL Ubuntu
#>

<#PSScriptInfo
    .VERSION 1.2.0

    .GUID 802367c6-654a-450b-94db-87e1d52e020a

    .AUTHOR Joel Bennett

    .COMPANYNAME HuddledMasses.org

    .COPYRIGHT Copyright (c) 2019-2023, Joel Bennett

    .TAGS Install Github Releases Binaries Linux Windows

    .LICENSEURI https://github.com/Jaykul/BoxStarter-Boxes/blob/master/LICENSE

    .PROJECTURI https://github.com/Jaykul/BoxStarter-Boxes

    .RELEASENOTES

    - **1.2.0** Added support for .zip files on Linux
                Also for checksum files based on the name "SHA256SUMS" instead of "checksums"
    - **1.1.0** Added support for directly downloading binaries (.exe on Windows, or no extension) to support earthly/earthly
    - **1.0.0** Broke this out from my BoxStarter Boxes, so I could share it more easily.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    # The user or organization that owns the repository
    [Parameter(Mandatory)]
    [Alias("User")]
    [string]$Org,

    # The name of the repository or project to download from
    [Parameter(Mandatory)]
    [string]$Repo,

    # The version (tag) of the release to download. Defaults to 'latest' which is always the latest release.
    [string]$Version = 'latest',

    # The location to install to. Defaults to $Env:LocalAppData\Programs on Windows, /usr/local/bin on Linux/MacOS
    [string]$BinDir
)

function Get-OSPlatform {
    [CmdletBinding()]
    param(
        [switch]$Pattern
    )
    $ri = [System.Runtime.InteropServices.RuntimeInformation]
    $platform = [System.Runtime.InteropServices.OSPlatform]
    # if $ri isn't defined, then we must be running in Powershell 5.1, which only works on Windows.
    $OS = if (-not $ri -or $ri::IsOSPlatform($platform::Windows)) {
        "windows"
    } elseif ($ri::IsOSPlatform($platform::Linux)) {
        "linux"
    } elseif ($ri::IsOSPlatform($platform::OSX)) {
        "darwin"
    } elseif ($ri::IsOSPlatform($platform::FreeBSD)) {
        "freebsd"
    } else {
        throw "unsupported platform"
    }
    if ($Pattern) {
        Write-Information $OS
        switch ($OS) {
            "windows" { "windows|(?<!dar)win" }
            "linux" { "linux|unix" }
            "darwin" { "darwin|osx" }
            "freebsd" { "freebsd" }
        }
    } else {
        $OS
    }
}

function Get-OSArchitecture {
    [CmdletBinding()]
    param(
        [switch]$Pattern
    )

    # PowerShell Core
    $Architecture = if (($arch = "$([Runtime.InteropServices.RuntimeInformation]::OSArchitecture)")) {
        $arch
        # Legacy Windows PowerShell
    } elseif ([Environment]::Is64BitOperatingSystem) {
        "X64";
    } else {
        "X86";
    }
    # Optionally, turn this into a regex pattern that usually works
    if ($Pattern) {
        Write-Information $arch
        switch ($arch) {
            "Arm" { "arm(?!64)" }
            "Arm64" { "arm64" }
            "X86" { "x86|386" }
            "X64" { "amd64|x64|x86_64" }
        }
    } else {
        $arch
    }
}

function Get-GitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias("User")]
        [string]$Org,

        [Parameter(Position = 1)]
        [string]$Repo,

        [Parameter(Position = 2)]
        [string]$Tag = 'latest'
    )

    Write-Debug "Checking GitHub for tag '$tag'"

    $result = if ($tag -eq 'latest') {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/$tag" -Headers @{Accept = 'application/json' } -Verbose:$false
    } else {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/tags/$tag" -Headers @{Accept = 'application/json' } -Verbose:$false
    }

    Write-Debug "Found tag '$($result.tag_name)' for $tag"
    $result
}

function Test-FileHash {
    <#
        .SYNOPSIS
            Test the hash of a file against one or more checksum files or strings
        .DESCRIPTION
            Checksum files are assumed to have one line per file name, with the hash (or multiple hashes) on the line following the file name.

            In order to support installing yq (which has a checksum file with multiple hashes), this function handles checksum files with an ARRAY of valid checksums for each file name by searching the array for any matching hash.

            This isn't great, but an accidental pass is almost inconceivable, and determining the hash order is too complicated (given only one weird project does this so far).
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        # The path to the file to check the hash of
        [string]$Target,

        # The hash(es) or checksum(s) to compare to (can be one or more files, or one or more hash strings)
        [string[]]$Checksum
    )

    # If Checksum is a file, get the checksum from the file
    if (Test-Path $Checksum) {
        $basename = [Regex]::Escape([IO.Path]::GetFileName($Target))
        Write-Debug "Checksum is a file, getting checksum for $basename from $checksum"
        $Checksum = (Select-String -LiteralPath $Checksum -Pattern $basename).Line -split "\s+|=" -notmatch $basename
    }

    $Actual = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
    # Supports checksum files with an ARRAY of valid checksums (for different hash algorithms)
    # ... by searching the array for any matching hash (an accidental pass is almost inconceivable).
    [bool]($Checksum -eq $Actual)
    if ($Checksum -eq $Actual) {
        Write-Verbose "Checksum matches $Actual"
    } else {
        Write-Error "Checksum mismatch!`nValid: $Checksum`nActual: $Actual"
    }
}

function Install-GitHubRelease {
    <#
    .SYNOPSIS
        Install a binary from a github release.
    .DESCRIPTION
        Cross-platform script to download, check file hash, and make sure the binary is on your PATH.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The user or organization that owns the repository
        [Parameter(Mandatory)]
        [Alias("User")]
        [string]$Org,

        # The name of the repository or project to download from
        [Parameter(Mandatory)]
        [string]$Repo,

        # The version of the release to download. Defaults to 'latest'
        [string]$Version = 'latest',

        # The operating system (will be detected, if not specified)
        $OS = (Get-OSPlatform -Pattern),

        # The architecture (will be detected, if not specified)
        $Architecture = (Get-OSArchitecture -Pattern),

        # The location to install to. Defaults to $Env:LocalAppData\Programs on Windows, /usr/local/bin on Linux/MacOS
        [string]$BinDir = $(if ($OS -notmatch "windows") { '/usr/local/bin' } elseif ($Env:LocalAppData) { "$Env:LocalAppData\Programs\Tools" } else { "$HOME/.tools" })
    )
    # A list of extensions in order of preference
    $extension = ".zip", ".tgz", ".tar.gz", ".exe"

    $release = Get-GitHubRelease @PSBoundParameters
    Write-Verbose "found release $($release.tag_name) for $org/$repo"

    $assets = $release.assets.where{ $_.name -match $OS -and $_.name -match $Architecture } |
        Select-Object *, @{ Name = "Extension"; Expr = { $_.name -replace '^[^.]+$', '' -replace ".*?((?:\.tar)?\.[^.]+$)", '$1' } } |
        Select-Object *, @{ Name = "Priority"; Expr = { if (($index = [array]::IndexOf($extension, $_.Extension)) -lt 0) { $index * -10 } else { $index } } } |
        Sort-Object Priority, Name

    if ($assets.Count -gt 1) {
        if ($asset = $assets.where({ $_.Extension -in $extension }, "First")) {
            Write-Warning "Found multiple assets for $OS/$Architecture`n $($assets| Format-Table name, Extension, b*url | Out-String)`nUsing $($asset.name)"
            # If it's not on windows, executables don't need an extesion
        } elseif ($os -notmatch "windows" -and ($asset = $assets.Where({ !$_.Extension }, "First", 0))) {
            Write-Warning "Found multiple assets for $OS/$Architecture`n $($assets| Format-Table name, Extension, b*url | Out-String)`nUsing $($asset.name)"
        } else {
            throw "Found multiple assets for $OS/$Architecture`n $($assets| Format-Table name, Extension, b*url | Out-String)`nUnable to detect usable release."
        }
    } elseif ($assets.Count -eq 0) {
        throw "No asset found for $OS/$Architecture`n $($release.assets.name -join "`n")"
    } else {
        $asset = $assets[0]
    }

    # Make a folder to unpack in
    $tempdir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tempdir | Out-Null
    Push-Location $tempdir

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $asset.name -Verbose:$false

    # There might be a checksum file
    $checksum = $release.assets.where{ $_.name -match "checksum|sha256sums" }[0]
    if ($checksum.Count -gt 0) {
        Write-Verbose "Found checksum file $($checksum.name)"
        Invoke-WebRequest -Uri $checksum.browser_download_url -OutFile $checksum.name -Verbose:$false

        if (!(Test-FileHash -Target $asset.name -Checksum $checksum.name)) {
            throw "Checksum mismatch for $($asset.name)"
        }
    } else {
        Write-Warning "No checksum file found for $($asset.name)"
    }

    # If it's an archive, expand it
    if ($asset.Extension -and $asset.Extension -ne ".exe") {
        $File = Get-Item $asset.name
        New-Item -Type Directory -Path $Repo | Convert-Path -OutVariable PackagePath | Set-Location
        Write-Verbose "Extracting $File to $PackagePath"

        if ($asset.Extension -eq ".zip") {
            Microsoft.PowerShell.Archive\Expand-Archive $File.FullName
        } else {
            if ($VerbosePreference -eq "Continue") {
                tar -xzvf $File.FullName
            } else {
                tar -xzf $File.FullName
            }
        }

        Set-Location $tempdir
    } else {
        Remove-Item $checksum.name
        $PackagePath = $tempdir
    }

    $Filter = @{ }
    if ($OS -match "windows") {
        $Filter.Include = @($ENV:PATHEXT -replace '\.', '*.' -split ';') + '*.exe'
    }

    if (!(Test-Path $BinDir)) {
        # First time use of $BinDir
        if ($Force -or $PSCmdlet.ShouldContinue("Create $BinDir and add to Path?", "$BinDir does not exist")) {
            New-Item -Type Directory -Path $BinDir | Out-Null
            if ($Env:PATH -split [IO.Path]::PathSeparator -notcontains $BinDir) {
                $Env:PATH += [IO.Path]::PathSeparator + $BinDir

                # If it's *not* Windows, $BinDir should be /usr/local/bin or something already in your PATH
                # Make the change permanent
                if ($OS -match "windows") {
                    $PATH = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
                    $PATH += [IO.Path]::PathSeparator + $BinDir
                    [Environment]::SetEnvironmentVariable("PATH", $PATH, [EnvironmentVariableTarget]::User)
                }
            }
        } else {
            throw "Cannot install $Repo to $BinDir"
        }
    }

    Write-Verbose "Moving files from $PackagePath"
    foreach ($File in Get-ChildItem $PackagePath -File -Recurse @Filter) {
        # Some teams (e.g. earthly/earthly), name the actual binary with the platform name, which is annoying
        if ($File.BaseName -match $OS -and $File.BaseName -match $Architecture ) {
            # $File = Rename-Item $File.FullName -NewName "$Repo$($_.Extension)" -PassThru
            if (!($NewName = ($File.BaseName -replace "[-_\.]*$OS" -replace "[-_\.]*$Architecture"))) {
                $NewName = $Repo
            }
            $NewName += $File.Extension
            Write-Warning "Renaming $File to $NewName"
            $File = Rename-Item $File.FullName -NewName $NewName -PassThru
        }
        # Some few teams include the docs with their package (e.g. opentofu)
        if ($File.BaseName -match "README|LICENSE|CHANGELOG" -or $File.Extension -in ".md", ".rst", ".txt", ".asc", ".doc" ) {
            Write-Verbose "Skipping doc $File"
            continue
        }
        Write-Verbose "Moving $File to $BinDir"

        if ($OS -notmatch "windows" -and (Get-Item $BinDir).Attributes -eq "ReadOnly,Directory") {
            sudo mv -f $File.FullName $BinDir
            sudo chmod +x "$BinDir/$($File.Name)"
        } else {
            if (Test-Path $BinDir/$($File.Name)) {
                Remove-Item $BinDir/$($File.Name) -Recurse -Force
            }
            Move-Item $File.FullName -Destination $BinDir -Force -ErrorAction Stop
            if ($OS -notmatch "windows") {
                chmod +x "$BinDir/$($File.Name)"
            }
        }
    }

    Pop-Location

    Remove-Item $tempdir -Recurse
}

Install-GitHubRelease @PSBoundParameters
