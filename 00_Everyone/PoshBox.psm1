filter RemoveAppX {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$appName
    )
    trap { continue } # If it doesn't work, just shut up and keep going
    $ErrorActionPreference = "SilentlyContinue"
    Write-Information "Trying to remove $appName" -InformationAction Continue
    Get-AppxPackage $appName -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppXProvisionedPackage -Online | Where DisplayName -like $appName | Remove-AppxProvisionedPackage -Online
}

filter InstallCodeExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$extension
    )
    Write-Information "Install extension $extension" -InformationAction Continue
    if (Get-Command code -ErrorAction Ignore) {
        code --install-extension $extension
    }
    if (Get-Command code-insiders -ErrorAction Ignore) {
        code-insiders --install-extension $extension
    }
}

# Eventually PSResource will be the default, and it's faster, so we'll use it, but only if it's already here
if (Get-Command Install-PSResource -ErrorAction Ignore) {
    Set-PSResourceRepository -Name PSGallery -Trusted
    filter UpdateModule {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [string]$module
        )
        Find-PSResource $module -Type Module | Where-Object {
            -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
        } | Install-PSResource -TrustRepository -AcceptLicense
    }
} else {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-PackageProvider NuGet -MinimumVersion 2.8.5.208 -ForceBootstrap

    filter UpdateModule {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
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

    # How about now?
    if (Get-Command Install-PSResource -ErrorAction Ignore) {
        filter UpdateModule {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [string]$module
            )
            Find-PSResource $module -Type Module | Where-Object {
                -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
            } | Install-PSResource -TrustRepository -AcceptLicense
        }
    }
}

function Finalize {
    [CmdletBinding()]param()
    $CallStack = Get-PSCallStack
    # CallStack[0] - this function
    # CallStack[n-1] - one of the ReadMe scripts, or the prompt
    # CallStack[n] - one of the ReadMe scripts, or the prompt
    # Thus, if the callstack is only 3 deep, we can run Finalize
    if ($CallStack.Count -le 3) {
        Enable-PSRemoting
        Enable-MicrosoftUpdate
        Install-WindowsUpdate -AcceptEula
        Enable-RemoteDesktop

        # Set-StartScreenOptions -EnableBootToDesktop -EnableDesktopBackgroundOnStart -EnableShowStartOnActiveScreen

        # This doesn't seem to work anymore
        # Install-ChocolateyPinnedTaskBarItem "${env:ProgramFiles}\Mozilla Firefox\firefox.exe"
        # Install-ChocolateyPinnedTaskBarItem (gcm code, code-insiders -ErrorAction SilentlyContinue | split-path | Split-Path | ls  -Filter Code*.exe | convert-path)

    }
}

#############################################################################
# Bootstrap the environment, in case PoshBox is imported outside BoxStarter #
#############################################################################
if (!(Get-Command choco -ErrorAction Ignore)) {
    Write-Host "Bootstrapping Chocolatey"
    Invoke-Expression (Invoke-RestMethod https://community.chocolatey.org/install.ps1)

    # Update the environment so that it works without a restart:
    $Env:ChocolateyInstall = [System.Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine")
    $Env:PATH = @($Env:PATH -split "\\?;" -ne "$Env:ChocolateyInstall\bin") + "$Env:ChocolateyInstall\bin" -join ";"
    # Aliases are faster than path searching
    Set-Alias choco (Convert-Path "$Env:ChocolateyInstall\bin\choco.exe")
}
Import-module (Convert-Path "$Env:ChocolateyInstall\helpers\chocolateyInstaller.psm1") -Scope Global

if (!(Get-Command Install-ChocolateyFont -ErrorAction Ignore)) {
    choco upgrade chocolatey-font-helpers.extension -y
    Import-Module "$Env:ChocolateyInstall\extensions\chocolatey-font-helpers\FontHelp.psm1" -Scope Global -ErrorAction Stop
}



if (-not (Get-Module Boxstarter.*).Count -ge 4) {
    Write-Host "Bootstrapping Boxstarter"

    choco upgrade -y boxstarter

    # Update PATH so it works "now"
    $Env:PSModulePath = $Env:PSModulePath + ';' + (Convert-Path "$Env:ProgramData\Boxstarter" -ErrorAction Stop)

    Import-Module Boxstarter.Chocolatey -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.Bootstrapper -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.Common -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.WinConfig -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
}