# Configure git to use plink so that keys from KeeAgent work
# Some day soon, I should try switching this to the Windows OpenSSH
choco upgrade -y putty.install
$plink = Get-Command plink | convert-path
[System.Environment]::SetEnvironmentVariable("GIT_SSH", $plink, "User")
