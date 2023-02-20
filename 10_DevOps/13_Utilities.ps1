# If you installed this from the windows store, and then logged in with the same account, it would already be installed...
if (!(Get-AppxPackage Microsoft.WindowsTerminal)) {
    choco upgrade -y microsoft-windows-terminal
}
choco upgrade -y delta
choco upgrade -y ripgrep
choco upgrade -y fzf
choco upgrade -y bat
choco upgrade -y yq
choco upgrade -y jq


choco upgrade -y git.install --package-parameters="'/GitOnlyOnPath /WindowsTerminal /NoShellIntegration /SChannel'"

# choco upgrade -y gitkraken
# choco upgrade -y filezilla
# choco upgrade -y cyberduck

## I tried using terraform for infrastructure as code, but I don't like it
# choco upgrade -y terraform
