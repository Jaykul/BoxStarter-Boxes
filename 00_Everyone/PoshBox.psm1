filter RemoveAppX {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$appName
    )
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

# Eventually PSResource will be the default, and it's faster, so we'll use it if it's here
if (Get-Command Install-PSResource -ErrorAction Ignore) {
    filter UpdateModule {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory,ValueFromPipeline)]
            [string]$module
        )
        Find-PSResource $module -Type Module | Where-Object {
            -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
        } | Install-PSResource -TrustRepository -AcceptLicense
    }
} else {
    filter UpdateModule {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory,ValueFromPipeline)]
            [string]$module
        )
        Find-Module $module | Where-Object {
            -not ( Get-Module -FullyQualifiedName @{ ModuleName = $_.Name; ModuleVersion = $_.Version } -ListAvailable )
        } | Install-Module -SkipPublisherCheck -AllowClobber -RequiredVersion { $_.Version }
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

function Invoke-Wsl {
    <#
        .SYNOPSIS
            Wrap wsl.exe with Console.Encoding because it ignores Console.Encoding
            This way when we get UTF-16 encoding the console handles it.
    #>
    [Console]::OutputEncoding, $Encoding = [Text.Encoding]::Unicode, [Console]::OutputEncoding
    wsl.exe @args
    [Console]::OutputEncoding = $Encoding
}

Set-Alias wsle Invoke-Wsl -Scope Global

function Add-WslUser {
    <#
        .SYNOPSIS
            Adds a user to a WSL distro
    #>
    [CmdletBinding()]
    param(
        # The distro to add the user to
        [Parameter(Mandatory)]
        $Distribution,

        # The user and password to add
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )
    # If we were interactive, you could leave off the --disabled-password and it would prompt
    if ($Credential.Password.Length -eq 0) {
        Write-Warning "Creating passwordless user"
        Write-Host "`n>" wsl "-d" $Distribution "-u" root adduser "--gecos" GECOS "--disabled-password" $Credential.UserName.ToLower()
        wsl -d $Distribution -u root adduser --gecos GECOS --disabled-password $Credential.UserName.ToLower()
    } else {
            Write-Host "`n>" wsl "-d" $Distribution "-u" root adduser "--gecos" GECOS $Credential.UserName.ToLower()
        "{0}`n{0}`n" -f $Credential.GetNetworkCredential().Password |
            wsl -d $Distribution -u root adduser --gecos GECOS $Credential.UserName.ToLower()
    }
    Write-Host "`n>" wsl "-d" $Distribution "-u" root usermod "-aG" sudo $Credential.UserName.ToLower()
    wsl -d $Distribution -u root usermod -aG sudo $Credential.UserName.ToLower()
}

function Install-WslDistro {
    <#
        .SYNOPSIS
            Installs a WSL Distribution non-interactively
    #>
    [CmdletBinding(DefaultParameterSetName="Secured")]
    param(
        # The distribution to install
        [Parameter(Position=0)]
        $Distribution = "ubuntu",

        # The default user for this distribution (by default, your user name, but all in lowercase)
        [Parameter(ParameterSetName="Insecure")]
        $Username = $Env:USERNAME.ToLower(),

        [Parameter(Mandatory, ParameterSetName="Secured")]
        [PSCredential]$Credential,

        [switch]$Default
    )
    # Install the distribution non-interactively
    Write-Host "`n>" wsl --install $Distribution --no-launch
    wsl --install $Distribution --no-launch
    Write-Host ">" $Distribution install --root
    &$Distribution install --root

    # Start-Sleep -Milliseconds 1000
    # Write-Host "`n>" wsl --install $Distribution
    # wsl --install $Distribution
    # Start-Sleep -Milliseconds 100
    # get-process $Distribution | stop-process

    # Then create the user after the fact
    if (!$Credential) {
        $Credential = [PSCredential]::new($Username.ToLower(), [securestring]::new())
    }
    Add-WslUser $Distribution $Credential

    # Sets the default user
    if (Get-Command $Distribution) {
        Write-Host $Distribution config --default-user $Credential.UserName.ToLower()
        & $Distribution config --default-user $Credential.UserName.ToLower()
    }

    if ($Default) {
        # Set the default distro to $Distribution
        Write-Host "`n>" wsl --set-default $Distribution
        wsl --set-default $Distribution
    }

    Write-Warning "$Distribution distro is installed. You may need to set a password with: wsl -d $Distribution -u root passwd $($Env:USERNAME.ToLower())"
}

#############################################################################
# Bootstrap the environment, in case PoshBox is imported outside BoxStarter #
#############################################################################
if (!(Get-Command choco)) {
    Write-Host "Bootstrapping Chocolatey" -NoNewline
    for ($x=0;$x-lt3;$x++) {
        Start-Sleep -Milliseconds 300
        Write-Host "." -NoNewline
    }
    Write-Host
    Invoke-Expression (Invoke-RestMethod https://community.chocolatey.org/install.ps1)

    # Update PATH so it works "now"
    $Env:PATH = $Env:PATH +";" + (Convert-Path "$Env:ProgramData\Chocolatey\bin" -ErrorAction Stop)
}

Import-module (Convert-Path "$Env:ProgramData\Chocolatey\helpers\chocolateyInstaller.psm1")

if (-not (Get-Module Boxstarter.*).Count -ge 4) {
    Write-Host "Bootstrapping Boxstarter" -NoNewline
    for ($x=0;$x-lt3;$x++) {
        Start-Sleep -Milliseconds 300
        Write-Host "." -NoNewline
    }
    Write-Host

    choco upgrade -y boxstarter

    # Update PATH so it works "now"
    $Env:PSModulePath = $Env:PSModulePath + ';' + (Convert-Path "$Env:ProgramData\Boxstarter" -ErrorAction Stop)

    Import-Module Boxstarter.Chocolatey -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.Bootstrapper -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.Common -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
    Import-Module Boxstarter.WinConfig -DisableNameChecking -ErrorAction SilentlyContinue -Scope Global
}