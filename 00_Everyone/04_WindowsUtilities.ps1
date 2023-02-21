# Over the years, Microsoft has added built-in screenshot and clipbard tools ...
# They are not as good as the ones I use, but I won't force my preferences on "everyone"
choco upgrade -y pwsh --install-arguments='"ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 REGISTER_MANIFEST=1 ENABLE_PSREMOTING=1"'
Start-Process "pwsh.exe" -verb runas -wait -argumentList "-noprofile -NoLogo -noninteractive -ExecutionPolicy unrestricted -WindowStyle hidden -Command `"Set-ExecutionPolicy RemoteSigned`""

# Everyone definitely needs a better archiver...
# choco upgrade -y 7zip.install
# Peazip's -ext2folder option is the best, for most people
choco upgrade -y peazip.install
foreach($path in Get-ChildItem $ENV:PROGRAMFILES/PeaZip -Recurse -Filter *.exe |
                    Where-Object Name -match "[a-z]+.exe") {
    Install-BinFile -Name $path.BaseName -Path $path.FullName
}