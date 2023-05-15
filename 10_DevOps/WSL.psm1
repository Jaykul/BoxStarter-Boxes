function Invoke-Wsl {
    <#
        .SYNOPSIS
            wsl.exe ignores Console.Encoding and always outputs UTF-16
            Set Console.Encoding to UTF-16 so the console can handle it
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
    [CmdletBinding(DefaultParameterSetName = "Secured")]
    param(
        # The distribution to install
        [Parameter(Position = 0)]
        $Distribution = "ubuntu",

        # The default user for this distribution (by default, your user name, but all in lowercase)
        [Parameter(ParameterSetName = "Insecure")]
        $Username = $Env:USERNAME.ToLower(),

        [Parameter(Mandatory, ParameterSetName = "Secured")]
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

function Install-WslKeeAgentPipe {
    <#
        .SYNOPSIS
            Install npiperelay and socat and configure SSH_AUTH_SOCK forwarding
    #>
    [CmdletBinding()]
    param(
        # The distribution to connect the pipe to
        [Parameter(Position = 0)]
        $Distribution = "Ubuntu",

        # The user for whom .bashrc should be modified
        # Defaults to your username all lowercase
        [Parameter(ParameterSetName = "Insecure")]
        $Username = $Env:USERNAME.ToLower(),

        # Ingore chocolatey for install (winget must be available).
        [switch]$NoChocolate
    )
    # Install npiperelay
    if (!(Get-Command npiperelay.exe -ErrorAction Ignore)) {
        if (-not $NoChocolate -and (Get-Command choco -ErrorAction Ignore)) {
            choco upgrade npiperelay -y
        } elseif (Get-Command winget -ErrorAction Ignore) {
            winget install --id=jstarks.npiperelay -e --accept-source-agreements
        } else {
            throw "Unable to install. Please download https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay_windows_amd64.zip and extract it somewhere in your PATH"
        }
    }

    # install socat in WSL
    wsl -d $Distribution -u root apt install socat
    if ($LASTEXITCODE) {
        throw "Unable to install socat. I give up."
    }

    # create the ssh-agent-pipe script in WSL
    # Ensure the carriage returns are correct (and fetch the script, if necessary):
    $script = if (Test-Path $PSScriptRoot\ssh-agent-pipe.sh) {
        (Get-Content $PSScriptRoot\ssh-agent-pipe.sh) -join "`n"
    } else {
        Invoke-RestMethod https://gist.githubusercontent.com/Jaykul/19e9f18b8a68f6ab854e338f9b38ca7b/raw/ssh-agent-pipe.sh
    }
    # escape $ and " so we can pass this through bash
    $script = $script -replace "\$", "\$" -replace '"', '\"'

    wsl -d $Distribution -u root -- bash -c "cat > /usr/local/bin/ssh-agent-pipe <<'EOF'`n${script}`nEOF"

    # Make it executable
    wsl -d $Distribution -u root chmod +x /usr/local/bin/ssh-agent-pipe

    # Add to .bashrc for the specified user
    wsl -d $Distribution -u $Username -- bash -c "echo `"source /usr/local/bin/ssh-agent-pipe`" >> ~/.bashrc"
}
