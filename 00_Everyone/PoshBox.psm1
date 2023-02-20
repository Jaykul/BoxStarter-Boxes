filter RemoveAppX {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]$appName
    )
    Write-Information "Trying to remove $appName" -InformationAction Continue
    Get-AppxPackage $appName -AllUsers | Remove-AppxPackage
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

function Add-WslUser {
    <#
        .SYNOPSIS
            Adds a user to a WSL distro
    #>
    [CmdletBinding()]
    param(
        # The distro to add the user to
        [ValidateSscript({
            if ((wsl --list -q) -notcontains $_) {
                throw "Distro not installed"
            }
            $true
        })]
        [Parameter(Mandatory)]
        $Distro,

        # The user and password to add
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )
    # If we were interactive, you could leave off the --disabled-password and it would prompt
    if ($Credential.Password.Length -eq 0) {
        Write-Warning "Creating passwordless user"
        wsl -d $Distro -u root adduser --gecos GECOS --disabled-password $Credential.UserName.ToLower()
    } else {
        "{0}`n{0}`n" -f $Credential.GetNetworkCredential().Password |
            wsl -d $Distro -u root adduser --gecos GECOS $Credential.UserName.ToLower()
    }
    wsl -d $Distro -u root usermod -aG sudo $WslUser
}

function Install-WslDistro {
    <#
        .SYNOPSIS
            Installs a WSL distro non-interactively
    #>
    [CmdletBinding(DefaultParameterSetName="Secured")]
    param(
        # The distro to install
        [ValidateSscript({
            if ((wsl --list --online -q) -notcontains $_) {
                throw "Distro not known to WSL"
            }
            if ((wsl --list -q) -contains $_) {
                throw "Distro already installed"
            }
            $true
        })]
        $Distro = "ubuntu",

        # The default user for this distro (by default, your user name, but all in lowercase)
        [Parameter(ParameterSetName="Insecure")]
        $Username = $Env:USERNAME.ToLower(),

        [Parameter(Mandatory, ParameterSetName="Secured")]
        [PSCredential]$Credential,

        [switch]$Default
    )
    # Install the distro non-interactively
    wsl --install -d $Distro --no-launch
    wsl --install -d $Distro

    # Then create the user after the fact
    if (!$Credential) {
        $Credential = [PSCredential]::new($Username, [securestring]::new())
    }
    Add-WslUser $Distro $Credential

    # Sets the default user to $WslUser
    if (Get-Command $Distro) {
        & $Distro config --default-user $WslUser
    }

    if ($Default) {
        # Set the default distro to $Distro
        wsl -s $Distro
    }

    Write-Warning "$Distro distro is installed. You may need to set a password with: wsl -d $Distro -u root passwd $($Env:USERNAME.ToLower())"
}