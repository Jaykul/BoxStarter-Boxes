# A while back I started using nerd fonts for all coding
# Import-Module "$Env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
function Install-NerdFont {
    param(
        [ValidateSet("3270","Agave","AnonymousPro","Arimo","AurulentSansMono","BigBlueTerminal","BitstreamVeraSansMono","CascadiaCode","CodeNewRoman","Cousine","DaddyTimeMono","DejaVuSansMono","DroidSansMono","FantasqueSansMono","FiraCode","FiraMono","Go-Mono","Gohu","Hack","Hasklig","HeavyData","Hermit","iA-Writer","IBMPlexMono","Inconsolata","InconsolataGo","InconsolataLGC","Iosevka","JetBrainsMono","Lekton","LiberationMono","Lilex","Meslo","Monofur","Monoid","Mononoki","MPlus","NerdFontsSymbolsOnly","Noto","OpenDyslexic","Overpass","ProFont","ProggyClean","RobotoMono","ShareTechMono","SourceCodePro","SpaceMono","Terminus","Tinos","Ubuntu","UbuntuMono","VictorMono")]
        [string[]]$Name = @("CascadiaCode", "FiraCode"),

        [string]$Version = $((Invoke-RestMethod https://github.com/ryanoasis/nerd-fonts/releases/latest -Headers @{Accept = 'application/json'}).tag_name -replace "^v")
    )
    # Hacking chocolatey a little bit
    $env:ChocolateyIgnoreChecksums = 'true'
    $env:ChocolateyPackageFolder = "$Env:ChocolateyInstall\lib\NerdFonts"

    # If they install them all, do it in alphabetical order
    foreach ($Font in $Name) {
        $packageArgs = @{
            packageName   = "NerdFonts"
            unzipLocation = "$Env:ChocolateyInstall\lib\NerdFonts\tools\$Font"
            url           = "https://github.com/ryanoasis/nerd-fonts/releases/download/v$Version/$Font.zip"
        }

        Install-ChocolateyZIPPackage @packageArgs
    }

    # Only install the "Windows Compatible" fonts, because otherwise we'll have double fonts
    $CompatibleFonts = Get-ChildItem $env:ChocolateyPackageFolder -File -Recurse -Filter "*Mono Windows Compatible*"
    Install-ChocolateyFont $CompatibleFonts.FullName -Multiple -ErrorAction Stop

}

Install-NerdFont
