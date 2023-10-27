<#
    .DESCRIPTION
        A cross-platform script to download, check the file hash, and make sure the binary is on your PATH.
    .SYNOPSIS
        Install a binary from a github release.
    .EXAMPLE
        Install-GithubRelease FluxCD Flux2

        Install `Flux` from the https://github.com/FluxCD/Flux2 repository
#>

<#PSScriptInfo
    .VERSION 1.0.1

    .GUID 802367c6-654a-450b-94db-87e1d52e020a

    .AUTHOR Joel Bennett

    .COMPANYNAME HuddledMasses.org

    .COPYRIGHT Copyright (c) 2019, Joel Bennett

    .TAGS Install Github Releases Binaries Linux Windows

    .LICENSEURI https://github.com/Jaykul/BoxStarter-Boxes/blob/master/LICENSE

    .PROJECTURI https://github.com/Jaykul/BoxStarter-Boxes

    .RELEASENOTES

        Broke this out from my BoxStarter Boxes, so I could share it more easily.
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
        switch($OS) {
            "windows" { "windows|(?<!dar)win" }
            "linux"   { "linux|unix" }
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
        switch($arch) {
            "Arm"   { "arm(?!64)" }
            "Arm64" { "arm64" }
            "X86"   { "x86|386" }
            "X64"   { "amd64|x64" }
        }
    } else {
        $arch
    }
}

function Get-GitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [Alias("User")]
        [string]$Org,

        [Parameter(Position=1)]
        [string]$Repo,

        [Parameter(Position=2)]
        [string]$Tag = 'latest'
    )

    Write-Debug "Checking GitHub for tag '$tag'"

    $result = if ($tag -eq 'latest') {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/$tag" -Headers @{Accept = 'application/json'} -Verbose:$false
    } else {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/tags/$tag" -Headers @{Accept = 'application/json'} -Verbose:$false
    }

    Write-Debug "Found tag '$($result.tag_name)' for $tag"
    $result
}

function Test-FileHash {
    [CmdletBinding()]
    param(
        [string]$Target,
        [string]$Checksum
    )

    # If Checksum is a file, get the checksum from the file
    if (Test-Path $Checksum) {
        $basename = [Regex]::Escape([IO.Path]::GetFileName($Target))
        Write-Debug "Checksum is a file, getting checksum for $basename from $checksum"
        $Checksum = (Select-String -LiteralPath $Checksum -Pattern $basename).Line -split "\s+|=" -notmatch $basename
    }

    $Actual = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
    $Actual -eq $Checksum
    if ($Actual -ne $Checksum) {
        Write-Error "Checksum mismatch!`nExpected: $Checksum`nActual: $Actual"
    } else {
        Write-Verbose "Checksum matches $Actual"
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
        [string]$BinDir = $(if ($OS -notmatch "windows") { '/usr/local/bin' } elseif ($Env:LocalAppData) { "$Env:LocalAppData/Programs" } else { "$HOME/.tools" })
    )

    $release = Get-GitHubRelease @PSBoundParameters
    Write-Verbose "found release $($release.tag_name) for $org/$repo"

    # I'll expand this later, these open with `tar -xzf`
    $format = "zip|tar.gz|tgz"
    $asset = $release.assets.where{ $_.name -match $OS -and $_.name -match $Architecture -and $_.name -match $format }

    if ($asset.Count -gt 1) {
        Write-Warning "Found multiple assets for $OS/$Architecture/$format, using $($asset[0].name)"
        $asset | Format-List name, browser_download_url | Out-String | Write-Verbose
        $asset = $asset[0]
    } elseif ($asset.Count -eq 0) {
        throw "No asset found for $OS/$Architecture/$format"
    }

    # Make a folder to unpack in
    $tempdir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tempdir | Out-Null
    Push-Location $tempdir

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $asset.name -Verbose:$false

    # There might be a checksum file
    $checksum = $release.assets.where{ $_.name -match "checksum" }[0]
    if ($checksum.Count -gt 0) {
        Write-Verbose "Found checksum file $($checksum.name)"
        Invoke-WebRequest -Uri $checksum.browser_download_url -OutFile $checksum.name -Verbose:$false

        if (!(Test-FileHash -Target $asset.name -Checksum $checksum.name)) {
            throw "Checksum mismatch for $($asset.name)"
        }
    } else {
        Write-Warning "No checksum file found for $($asset.name)"
    }

    $File = Get-Item $asset.name
    New-Item -Type Directory -Path $Repo | Convert-Path -OutVariable PackagePath | Set-Location
    Write-Verbose "Extracting $File to $PackagePath"
    tar -xzf $File.FullName

    Set-Location $tempdir

    $Filter = if ($OS -match "windows") {
        @{
            Include = @($ENV:PATHEXT -replace '\.', '*.' -split ';') + '*.exe'
        }
    } else {
        @{
            Exclude = '*.*'
        }
    }

    if (!(Test-Path $BinDir)) {
        # First time use of $BinDir
        if ($Force -or $PSCmdlet.ShouldContinue("Created $BinDir", "Create $BinDir?", "$BinDir does not exist")) {
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