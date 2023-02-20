#--- Uninstall unnecessary applications that come with Windows out of the box ---
Write-Host "Uninstall some applications that come with Windows out of the box" -ForegroundColor "Yellow"

#Referenced to build script
# https://docs.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update
# https://github.com/jayharris/dotfiles-windows/blob/master/windows.ps1#L157
# https://gist.github.com/jessfraz/7c319b046daa101a4aaef937a20ff41f
# https://gist.github.com/alirobe/7f3b34ad89a159e6daa1
# https://github.com/W4RH4WK/Debloat-Windows-10/blob/master/scripts/remove-default-apps.ps1


@(
    "*.AdobePhotoshopExpress"
    "*.Duolingo-LearnLanguagesforFree"
    "*.EclipseManager"
    "*Autodesk*"
    "*BubbleWitch*"
    "*Facebook*"
    "*Keeper*"
    "*MarchofEmpires*"
    "*Minecraft*"
    "*Netflix*"
    "*Solitaire*"
    "*Twitter*"
    "ActiproSoftwareLLC.562882FEEB491" # Code Writer
    "Microsoft.3DBuilder"
    "Microsoft.BingFinance"
    "Microsoft.BingFinance"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingWeather"
    "Microsoft.CommsPhone"
    "Microsoft.FreshPaint"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Messaging"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.NetworkSpeedTest"
    "Microsoft.Office.Sway"
    "Microsoft.OneConnect"
    "Microsoft.Print3D"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsPhone"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.XboxApp"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "Clipchamp.Clipchamp"
    "Microsoft.BingNews"
    "Microsoft.DesktopAppInstaller"
    "Microsoft.GamingApp"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MSPaint"
    "Microsoft.Office.OneNote"
    "Microsoft.Paint"
    "Microsoft.People"
    "Microsoft.PowerAutomateDesktop"
    "Microsoft.ScreenSketch"
    "Microsoft.SkypeApp"
    "Microsoft.VP9VideoExtensions"
    "Microsoft.WindowsNotepad"
    # ? "Microsoft.Wallet"
    # "Microsoft.549981C3F5F10" # Cortana
    # "Microsoft.HEIFImageExtension"
    # "Microsoft.Microsoft3DViewer"
    # "Microsoft.MicrosoftEdge.Beta"
    # "Microsoft.MicrosoftEdge.Dev"
    # "Microsoft.MicrosoftEdge.Stable"
    # "Microsoft.MixedReality.Portal"
    # "Microsoft.RawImageExtension"
    # "Microsoft.SecHealthUI"
    # "Microsoft.StorePurchaseApp"
    # "Microsoft.Todos"
    # "Microsoft.WebMediaExtensions"
    # "Microsoft.WebpImageExtension"
    # "Microsoft.Windows.Photos"
    # "Microsoft.WindowsAlarms"
    # "Microsoft.WindowsCalculator"
    # "Microsoft.WindowsCamera"
    # "microsoft.windowscommunicationsapps"
    # "Microsoft.WindowsFeedbackHub"
    # "Microsoft.WindowsStore"
    # "Microsoft.WindowsTerminal"
    # "Microsoft.Xbox.TCUI"
    # "Microsoft.XboxGameOverlay"
    # "Microsoft.XboxGamingOverlay"
    # "Microsoft.XboxSpeechToTextOverlay"
    # "Microsoft.YourPhone"
    # "MicrosoftCorporationII.QuickAssist"
    # "MicrosoftWindows.Client.WebExperience"
) | RemoveAppX