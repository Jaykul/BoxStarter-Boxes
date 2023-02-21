<#
    .SYNOPSIS
        Installs VS Code and (Azure) DevOps tools
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
Push-Location

# If this script is being run DIRECTLY via Boxstarter, we need to clone the rest of the repository
if ($Boxstarter -and (Convert-Path (Join-Path "$PSScriptRoot\" ..\[015]*\Install.ps1)).Count -lt 3) {
    $tendir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tendir | Out-Null
    Set-Location $tendir
    Write-Host "Cloning BoxStarter-Boxes"

    & { # Git sucks:
        $fatal = @();
        $outputStream = ""
        $outputMessage = @()
        $ErrorActionPreference, $oldErrorAction = 'Continue', $ErrorActionPreference
        $Output = git clone https://github.com/Jaykul/BoxStarter-Boxes.git Boxes 2>&1
        $ErrorActionPreference = $oldErrorAction
        # This empty error record causes an extra iteration to flush the output
        switch (@($Output) + ([System.Management.Automation.ErrorRecord]::new([Exception]::new(""), "NotAnError", "NotSpecified", $null))) {
            { $_ -is [System.Management.Automation.ErrorRecord] } {
                # git writes "fatal" (Terminating), "error" (non-terminating), "warning", and verbose output to stderr.
                # We output them as they come in, but we save "fatal" for the end because it ends the command
                $null = $_.Exception.Message -match "^((?<stream>fatal|error|warning):)?\s*(?<message>.*)$"
                $message = $Matches["message"]
                $stream = if ($Matches["stream"]) { $Matches["stream"] } else { "Verbose" }
                Write-Host "$([char]27)[38;2;255;0;0m$([char]27)[48;2;255;255;255m $stream $([char]27)[38;2;255;255;255m$([char]27)[49m $message"
                # If this is the same stream as the last one, then append the output
                if ($outputStream -eq $stream -and $message.Length) {
                    $outputMessage = @($outputMessage) + $message
                } else {
                    # Otherwise, if we've captured output, write the output and start anew
                    if ($outputMessage) {
                        if ($outputStream -eq "fatal") {
                            $fatal = @($fatal) + $outputMessage
                        } else {
                            . "Write-$outputStream" ($outputMessage.ForEach("Trim") -Join "`n") -ErrorAction $ErrorActionPreference -Verbose:$($VerbosePreference -notin "Ignore", "SilentlyContinue")
                        }
                    }
                    $outputMessage = @($message)
                }
                $outputStream = $stream
            }
            default { $_ } # Normal output just passes through
        }
        if ($fatal -or $LASTEXITCODE -ne 0) {
            Write-Error "LASTEXITCODE: $LASTEXITCODE. Failed to clone BoxStarter-Boxes. $fatal"
            exit 1
        }
    }
    Set-Location Boxes\10_DevOps
}

& (Join-Path $PSScriptRoot ..\0*\Install.ps1) @PSBoundParameters

Write-Host "=== DEVOPS ==="

# I'm giving in to the easy way. This way it's easier to customize by deleting the files you don't want
foreach ($file in Get-ChildItem $PSScriptRoot -Filter "??_*.ps1") {
    Write-Host "=== $($file.Name) ==="
    & $file.FullName
}

Pop-Location
if ($tendir) {
    Remove-Item $tendir -Recurse -Force -ErrorAction Continue
}

Finalize