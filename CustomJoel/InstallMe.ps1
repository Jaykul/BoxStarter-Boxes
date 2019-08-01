mkdir ~\Projects -Force
mkdir ~\Projects\Platform -Force
mkdir ~\Projects\Modules -Force
mkdir ~\Projects\Provisioning -Force

git config --global user.email "Joel.Bennett@Questionmark.com"
git config --global user.name  "Joel Bennett"
git config --global core.autocrlf "input"

if (Get-Command code -ErrorAction Ignore) {
    git config --global core.editor = code --wait
}
if (Get-Command code-insiders -ErrorAction Ignore) {
    git config --global core.editor = code-insiders --wait
}

<##### TODO: git clone the core work projects ...
cd ~\Projects\Modules
git clone
cd ~\Projects\Platform
#>


<##### TODO: copy down my profile and projects from azure
Set-BingWallpaper
#>