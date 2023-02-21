[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [Alias("User")]
    [string]$Org,

    [Parameter(Mandatory)]
    [string]$Repo,

    [string]$Version = 'latest'
)

function Get-OSPlatform {
    [CmdletBinding()]
    param(
        [switch]$Pattern
    )
    $ri = [System.Runtime.InteropServices.RuntimeInformation]
    $platform = [System.Runtime.InteropServices.OSPlatform]
    # if $ri isn't defined, then we must be running in Powershell 5.1, which only works on Windows.
    $os = if (-not $ri -or $ri::IsOSPlatform($platform::Windows)) {
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
        Write-Information $os
        switch($os) {
            "windows" { "windows|win" }
            "linux"   { "linux|unix" }
            "darwin"  { "darwin|osx" }
            "freebsd" { "freebsd" }
        }
    } else {
        $os
    }
}

function Get-OSArchitecture {
    [CmdletBinding()]
    param(
        [switch]$Pattern
    )

    # PowerShell Core
    $arch = if (($arch = "$([Runtime.InteropServices.RuntimeInformation]::OSArchitecture)")) {
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
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/$tag" -Headers @{Accept = 'application/json'}
    } else {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/tags/$tag" -Headers @{Accept = 'application/json'}
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
    }
}

function Install-GitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias("User")]
        [string]$Org,

        [Parameter(Mandatory)]
        [string]$Repo,

        [string]$Version = 'latest'
    )

    $release = Get-GitHubRelease @PSBoundParameters
    Write-Verbose "found release $($release.tag_name) for $org/$repo"

    $os = Get-OSPlatform -Pattern
    $arch = Get-OSArchitecture -Pattern
    # We really only support things that come in zips
    $format = "zip|tar.gz|tgz|7z"
    $asset = $release.assets.where{ $_.name -match $os -and $_.name -match $arch -and $_.name -match $format }

    if ($asset.Count -gt 1) {
        Write-Warning "Found multiple assets for $os/$arch/$format, using $($asset[0].name)"
        $asset | Select-Object name, browser_download_url | Format-List | Write-Verbose
        $asset = $asset[0]
    }

    # Make a folder to unpack in
    $tempdir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tempdir | Out-Null
    Push-Location $tempdir

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $asset.name

    # There might be a checksum file
    $checksum = $release.assets.where{ $_.name -match "checksum" }[0]
    if ($checksum.Count -gt 0) {
        Write-Verbose "Found checksum file $($checksum.name)"
        Invoke-WebRequest -Uri $checksum.browser_download_url -OutFile $checksum.name

        if (!(Test-FileHash -Target $asset.name -Checksum $checksum.name)) {
            throw "Checksum mismatch for $($asset.name)"
        }
    } else {
        Write-Warning "No checksum file found for $($asset.name)"
    }

    peazip -ext2folder $asset.name

    foreach ($Name in Get-ChildItem $tempdir -Directory -Name) {
        if (Test-Path $Env:LocalAppData\Programs\$name) {
            Remove-Item $Env:LocalAppData\Programs\$name -Recurse -Force
        }
        Move-Item $Name -Destination $Env:LocalAppData\Programs -Force

        foreach($path in Get-ChildItem $Env:LocalAppData\Programs\$name -Filter *.exe) {
            Install-BinFile -Name $path.BaseName -Path $path.FullName
        }
    }
}

Install-GitHubRelease @PSBoundParameters