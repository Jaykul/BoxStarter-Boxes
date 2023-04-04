try {
    Enable-PSRemoting -Force
} catch {
    Write-Warning "Failed to enable PSRemoting: $_"
}

# choco upgrade -y powershell-core
# choco upgrade -y powershell-preview

@(
    "Pansies"
    "PowerLine"
) | UpdateModule

if ($WindowsTerminalSettings = Convert-Path "$Env:LocalAppData\packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -ErrorAction Ignore) {
    Get-Content $WindowsTerminalSettings -Raw | ConvertFrom-Json -AsHashtable | Update-Object @{
        profiles = @{
            defaults = @{
                font = @{
                    face = "CaskaydiaCove NFM"
                }
            }
        }
    } | ConvertTo-Json -Depth 100 | Set-Content $WindowsTerminalSettings
}
