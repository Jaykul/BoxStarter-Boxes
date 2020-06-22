Install-Module Pansies -AllowPrerelease -AllowClobber
Install-Module PowerLine -AllowPrerelease -AllowClobber

Install-Module MSTerminalSettings -AllowPrerelease
Get-MSTerminalProfile | Set-MSTerminalProfile -FontFace "Cascadia Code PL"

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -FullColor -Timestamp -Newline -Save

Push-Location ~\Projects\Modules
git clone https://github.com/Jaykul/Profile.git Profile