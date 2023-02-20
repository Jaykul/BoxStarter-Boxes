# choco upgrade -y powershell-core
# choco upgrade -y powershell-preview

@(
    "Pansies"
    "PowerLine"
    "MSTerminalSettings"
) | UpdateModule

Get-MSTerminalProfile | Set-MSTerminalProfile -FontFace "Caskaydia Cove NFM"

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -FullColor -Timestamp -Newline -Save

Enable-PSRemoting -Force

# Push-Location ~\Projects\Modules
# git clone https://github.com/Jaykul/Profile.git Profile