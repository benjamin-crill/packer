<#
.FUNCTIONALITY
-Runs default user best practices for non-persisent workloads
-Includes code from https://raw.githubusercontent.com/JonathanPitre/Scripts/master/Default%20User%20Profile/Optimize-DefaultUserProfile.ps1

.SYNOPSIS
-Runs default user best practices for non-persisent workloads
-Includes code from https://raw.githubusercontent.com/JonathanPitre/Scripts/master/Default%20User%20Profile/Optimize-DefaultUserProfile.ps1

.NOTES
Change log


#> 

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
$env:SEE_MASK_NOZONECHECKS = 1
$Modules = @("PSADT") # Modules list
#$FrenchCaLangPack = (Get-ItemProperty -Path "hklm:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name FrenchCaLangPack -ErrorAction SilentlyContinue).FrenchCaLangPack

Function Get-ScriptDirectory
{
    Remove-Variable appScriptDirectory
    Try
    {
        If ($psEditor) { Split-Path $psEditor.GetEditorContext().CurrentFile.Path } # Visual Studio Code Host
        ElseIf ($psISE) { Split-Path $psISE.CurrentFile.FullPath } # Windows PowerShell ISE Host
        ElseIf ($PSScriptRoot) { $PSScriptRoot } # Windows PowerShell 3.0-5.1
        Else
        {
            Write-Host -Object "Cannot resolve script file's path" -ForegroundColor Red
            Exit 1
        }
    }
    Catch
    {
        Write-Host -Object "Caught Exception: $($Error[0].Exception.Message)" -ForegroundColor Red
        Exit 2
    }
}


# Get the current script directory
$appScriptDirectory = Get-ScriptDirectory


#-----------------------------------------------------------[Functions]------------------------------------------------------------

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$appProcesses = @("regedit", "reg")
#$appTeamsConfigURL = "https://raw.githubusercontent.com/JonathanPitre/Apps/master/Microsoft/Teams/desktop-config.json"
#$appTeamsConfig = Split-Path -Path $appTeamsConfigURL -Leaf
$NewUserScript = "\\$envMachineADDomain\NETLOGON\Citrix\NewUserProfile\Set-NewUserProfile.ps1" # Modify according to your environment

#-----------------------------------------------------------[Execution]------------------------------------------------------------


Get-Process -Name $appProcesses | Stop-Process -Force
Set-Location -Path $appScriptDirectory

# Backup Default User registry hive
Write-Log -Message "Saving a Default User registry hive copy..." -Severity 1 -LogType CMTrace -WriteHost $True
If (-Not(Test-Path -Path "$envSystemDrive\Users\Default\NTUSER.DAT.bak"))
{
    Copy-File -Path "$envSystemDrive\Users\Default\NTUSER.DAT" -Destination "$appScriptDirectory\NTUSER.DAT.BAK"
}

# Load the Default User registry hive
Write-Log -Message "Loading the Default User registry hive..." -Severity 1 -LogType CMTrace -WriteHost $True
Start-Sleep -Seconds 5
Execute-Process -Path "$envWinDir\System32\reg.exe" -Parameters "LOAD HKLM\DefaultUser $envSystemDrive\Users\Default\NTUSER.DAT" -WindowStyle Hidden

# Set Sounds scheme to none
$RegKeys = Get-ChildItem -Path "HKLM:\DefaultUser\AppEvents\Schemes\Apps\.Default" -Recurse | Select-Object -ExpandProperty Name | ForEach-Object { $_ -replace "HKEY_LOCAL_MACHINE" , 'HKLM:' }
ForEach ($Items in $RegKeys)
{
    Set-RegistryKey -Key $Items -Name "(Default)" -Value ""
}

# Disable sound beep
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Sound" -Name "Beep" -Type String -Value "no"
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Sound" -Name "ExtendedSounds" -Type String -Value "no"

# Force asynchronous processing of user GPOs at first logon - https://james-rankin.com/articles/make-citrix-logons-use-asynchronous-user-group-policy-processing-mode
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Group Policy\State" -Name "NextRefreshReason" -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Group Policy\State" -Name "NextRefreshMode" -Type DWord -Value "2"

# Disable action center
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value "0"

# Add "This PC" to desktop
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Type DWord -Value "0"

# Advertising ID
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value "0"

# Set wallpaper
#Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "WallPaper" -Type String -Value ""
#Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "WallPaperStyle" -Type String -Value "10"

# Disable peer-to-peer caching but still allows Delivery Optimization to download content over HTTP from the download's original source - https://docs.microsoft.com/en-us/windows/deployment/update/waas-delivery-optimization-reference#download-mode
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Type DWord -Value "3"

# Show known file extensions
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value "0"

# Change default explorer view to my computer
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value "1"

# Show Taskbar on one screen and show icons where taskbar is open
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MMTaskbarEnabled" -Type DWord -Value "1"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MMTaskbarMode" -Type DWord -Value "2"

# Show search box on the taskbar
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value "2"

# Disable Security and Maintenance Notifications
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" -Name "Enabled" -Type DWord -Value "0"

# Hide Windows Ink Workspace Button
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" -Name "PenWorkspaceButtonDesiredVisibility" -Type DWord -Value "0"

# Disable Game DVR
Set-RegistryKey -Key "HKLM:\DefaultUser\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value "0"

# Disable the label "Shortcut To" on shortcuts - https://www.howtogeek.com/howto/windows-vista/remove-shortcut-text-from-new-shortcuts-in-vista
$ValueHex = "00,00,00,00"
$ValueHexified = $ValueHex.Split(",") | ForEach-Object { "0x$_"}
$ValueBinary = ([byte[]]$ValueHexified)
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "link" -Type Binary -Value $ValueBinary

# Show ribbon in File Explorer
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Windows\Explorer" -Name "ExplorerRibbonStartsMinimized" -Type DWord -Value "2"

# Hide Taskview button on Taskbar
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value "0"

# https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909
# Disable checkboxes File Explorer
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AutoCheckSelect" -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideIcons" -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect " -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListViewShadow" -Type DWord -Value "1"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowInfoTip" -Type DWord -Value "0"
# Visual effects - Disable "Animations in the taskbar" - https://virtualfeller.com/2015/11/19/windows-10-optimization-part-4-user-interface
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value "0"
# Hide People button from Taskbar
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\AnimateMinMax" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ComboBoxAnimation" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\ControlAnimations" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMAeroPeekEnabled" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\DWMSaveThumbnailEnabled" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\MenuAnimation" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\SelectionFade" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TaskbarAnimations" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TooltipAnimation" -Name "DefaultApplied" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord-Value "0"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord-Value "0"

# Always show alll icons and notifications on the taskbar -   https://winaero.com/blog/always-show-tray-icons-windows-10
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type DWord -Value "0"

# Speed up logoff
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "AutoEndTasks" -Type String -Value "1"
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Type String -Value "2000"
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "HungAppTimeout" -Type String -Value "1000"

# Optimizes Explorer and Start Menu responses Times - https://docs.citrix.com/en-us/workspace-environment-management/current-release/reference/environmental-settings-registry-values.html
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "InteractiveDelay" -Type DWord -Value "40"

# Visual Effects
# Settings "Visual effects to Custom" - https://support.citrix.com/article/CTX226368
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value "3"

# Change Windows Visual Effects - https://virtualfeller.com/2015/11/19/windows-10-optimization-part-4-user-interface
# https://superuser.com/questions/839993/find-registry-key-for-windows-8-per-application-input-method-setting
$ValueHex = "90,24,03,80,10,00,00,00"
$ValueHexified = $ValueHex.Split(",") | ForEach-Object { "0x$_"}
$ValueBinary = ([byte[]]$ValueHexified)
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "UserPreferencesMask" -Type $ValueBinary -Value "0"

# Specifies how much time elapses between each blink of the selection cursor
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "CursorBlinkRate" -Type String -Value "-1"

# Disable Cursor Blink
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "DisableCursorBlink" -Type DWord -Value "1"

# Visual effects - Disable "Show window contents while dragging"
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value "0"

# Reduces the Start menu display interval
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "10"

# Disable smooth scrolling
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop" -Name "SmoothScroll" -Type DWord-Value "0"

# Visual effects - Disable "Animate windows when minimizing and maximizing"
Set-RegistryKey -Key "HKLM:\DefaultUser\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "0"

# Expand to open folder
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NavPaneExpandToCurrentFolder" -Type DWord -Value "1"

# Show all folders
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NavPaneShowAllFolders" -Type DWord -Value "1"

# Always show menus
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AlwaysShowMenus" -Type DWord -Value "1"

# Display Full Path in Title Bar
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -Type DWord -Value "1"

# Visual effects - Disable "Show thumbnails instead of icons"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Type DWord -Value "0"
# Enable Thumbnail Previews
Remove-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableThumbnails"
Remove-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableThumbnails"

# Visual effects - Disable "Enable Peek" - https://www.tenforums.com/tutorials/47266-turn-off-peek-desktop-windows-10-a.html
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisablePreviewDesktop" -Type DWord -Value "1"

# Visual effects - Disable "Aero Peek" - https://virtualfeller.com/2015/11/19/windows-10-optimization-part-4-user-interface
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value "0"

# Visual effects - Disable "Save taskbar thumbnail previews" - https://virtualfeller.com/2015/11/19/windows-10-optimization-part-4-user-interface
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\DWM" -Name "AlwaysHibernateThumbnails" -Type DWord -Value "0"

# Set the Title And Border Color to black - https://dybbugt.no/2020/1655 - https://winaero.com/blog/enable-dark-title-bars-custom-accent-color-windows-10
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\DWM" -Name "AccentColor" -Type DWord -Value "4292311040"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\DWM" -Name "ColorizationColor" -Type DWord -Value "4292311040"

# Enable the Border and title bar coloring - https://dybbugt.no/2020/1655
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\DWM" -Name "ColorPrevalence" -Type DWord -Value "1"

# Remove "Recently added" list from Start Menu
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type DWord -Value "1"

# Do not show the 'new application installed' notification
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Windows\Explorer" -Name "NoNewAppAlert" -Type DWord -Value "1"

# Makes Citrix Director reports logons slightly faster - https://james-rankin.com/articles/how-to-get-the-fastest-possible-citrix-logon-times
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Type String -Value "0"

# Internet Explorer
# Disable warning "Protected mode is turned off for the Local intranet zone" - https://www.carlstalhood.com/group-policy-objects-vda-user-settings
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Internet Explorer\Main" -Name "NoProtectedModeBanner" -Type DWord -Value "1"

# Microsoft Office 365/2016/2019
# Removes the First Things First (EULA) - https://social.technet.microsoft.com/Forums/ie/en-US/d8867a27-894b-44ff-898d-24e0d0c6838a/office-2016-proplus-first-things-first-eula-wont-go-away?forum=Office2016setupdeploy
# https://www.carlstalhood.com/group-policy-objects-vda-user-settings/#office2013
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\16.0\Registration" -Name "AcceptAllEulas" -Type DWord -Value "1"

# Limit Office 365 telemetry - https://www.ghacks.net/2020/11/15/limit-office-365-telemetry-with-this-undocumented-setting
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\Common\ClientTelemetry" -Name "DisableTelemetry" -Type DWord -Value "1"

# Disable "Your Privacy Option" message - http://www.edugeek.net/forums/office-software/218099-office-2019-your-privacy-option-popup.html
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common" -Name "PrivacyNoticeShown" -Type DWord -Value "2"

# Disable "Your Privacy Matters" message - https://www.reddit.com/r/sysadmin/comments/q6sesu/office_2021_your_privacy_matters_disable_via_gpo
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\common\Privacy\SettingsStore\Anonymous" -Name "OptionalConnectedExperiencesNoticeVersion" -Type DWord -Value "2"

# Disable "Show the option for Office Insider" - https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\16.0\Common" -Name "InsiderSlabBehavior" -Type DWord -Value "2"
# Set Outlook's Cached Exchange Mode behavior - https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\16.0\Outlook\Cached Mode" -Name "Enable" -Type DWord -Value "1"
# 1 month sync
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\16.0\Outlook\Cached Mode" -Name "SyncWindowSetting" -Type DWord -Value "1"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\16.0\Outlook\Cached Mode" -Name "CalendarSyncWindowSetting" -Type DWord -Value "1"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Policies\Microsoft\Office\16.0\Outlook\Cached Mode" -Name "CalendarSyncWindowSettingMonths" -Type DWord -Value "1"

# Disable teaching callouts - https://docs.microsoft.com/en-us/answers/questions/186354/outlook-remove-blue-tip-boxes.html
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "AutocreateTeachingCallout_MoreLocations" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "AutoSaveFirstSaveWord" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "AutoSaveTottleOnWord" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "CloudSettingsSyncTeachingCallout" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "CommingSoonTeachingCallout" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "DataVisualizerRibbonTeachingCallout" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "ExportToWordProcessTabTeachingCallout" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "FocusedInboxTeachingCallout_2" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "MeetingAllowForwardTeachingCallout" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "Olk_SearchBoxTitleBar_SLR_Sequence" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "PreviewPlaceUpdate" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "RibbonOverflowTeachingCalloutID" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "Search.TopResults" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "SLRToggleReplaceTeachingCalloutID" -Type DWord -Value "2"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\TeachingCallouts" -Name "UseTighterSpacingTeachingCallout" -Type DWord -Value "2"

# Remove the default file types dialog - https://www.blackforce.co.uk/2016/05/11/disable-office-2016-default-file-types-dialog
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\General" -Name "ShownFileFmtPrompt" -Type DWord -Value "1"

# Remove the "Get and set up Outlook Mobile app on my phone" option from Outlook - https://support.microsoft.com/en-ca/help/4010175/disable-the-get-and-set-up-outlook-mobile-app-on-my-phone-option
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DisableOutlookMobileHyperlink" -Type DWord -Value "1"

# Enable Microsoft OneNote page tabs appear on the left - https://social.technet.microsoft.com/Forums/en-US/b5cad42a-83a6-4f19-96ed-70e6a3f964de/onenote-how-to-move-page-window-to-the-left-side?forum=officeitproprevious
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\onenote\Options\Other" -Name "PageTabsOnLeft" -Type DWord -Value "1"

# Open Microsoft Visio diagrams and drawings in separate windows
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Visio\Application" -Name "SingleInstanceFileOpen" -Type String -Value "0"

# Disable the Microsoft Office Upload Center notification - https://www.ghacks.net/2018/02/09/how-to-disable-the-microsoft-office-upload-center
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\FileIO" -Name "DisableNotificationIcon" -Type String -Value "1"

# Disable Micrososoft Office hardware graphics acceleration - http://shawnbass.com/psa-software-gpu-can-reduce-your-virtual-desktop-scalability
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\16.0\Common\Graphics" -Name "DisableHardwareAcceleration" -Type String -Value "1"

# Disable Micrososoft OneDrive Notifications - https://docs.microsoft.com/en-us/archive/blogs/platforms_lync_cloud/disabling-windows-10-action-center-notifications
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop" -Name "Enabled" -Type DWord -Value "0"

# Get Micrososoft OneDrive setups run keys
$OneDriveSetup = Get-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Run" -Value "OneDriveSetup"
$OneDrive = Get-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Run" -Value "OneDrive"

# Remove Microsoft OneDrive setups from running on new user profile
# https://byteben.com/bb/installing-the-onedrive-sync-client-in-per-machine-mode-during-your-task-sequence-for-a-lightening-fast-first-logon-experience
If ($OneDriveSetup) { Remove-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" }
If ($OneDrive) { Remove-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" }

# Set Microsoft Teams as the default chat app for Office - https://www.msoutlook.info/question/setting-skype-or-other-im-client-to-integrate-with-outlook
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\IM Providers" -Name "DefaultIMApp" -Type String -Value "Teams"

# Open Microsoft Teams links without prompts - https://james-rankin.com/articles/microsoft-teams-on-citrix-virtual-apps-and-desktops-part-2-default-settings-and-json-wrangling
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Classes\msteams\shell\open\command" -Name "(Default)" -Type String -Value "`"C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe`" `"%1`""
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Classes\TeamsURL\shell\open\command" -Name "(Default)" -Type String -Value "`"C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe`" `"%1`""
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Classes\msteams" -Name "DefaultIMApp" -Type String -Value "URL:msteams"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" -Name "msteams_msteams" -Type DWord -Value "00000000"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Classes\msteams" -Name "URL Protocol" -Type String -Value ""
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Internet Explorer\ProtocolExecute\msteams" -Name "WarnOnOpen" -Type String -Value "00000000"

# Download required Microsoft Teams config file
If (-Not(Test-Path -Path $appScriptDirectory\$appTeamsConfig))
{
    Write-Log -Message "Downloading Microsoft Teams config file..." -Severity 1 -LogType CMTrace -WriteHost $True
    Invoke-WebRequest -UseBasicParsing -Uri $appTeamsConfigURL -OutFile $appScriptDirectory\$appTeamsConfig
}
Else
{
    Write-Log -Message "File(s) already exists, download was skipped." -Severity 1 -LogType CMTrace -WriteHost $True
}

# Copy Microsoft Teams config file to the default profile
#Copy-File -Path "$appScriptDirectory\$appTeamsConfig" -Destination "$envSystemDrive\Users\Default\AppData\Roaming\Microsoft\Teams"

# To validate (from the comments section)
#Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Classes\WOW6432Node\CLSID\{00425F68-FFC1-445F-8EDF-EF78B84BA1C7}\LocalServer" -Name "(Default)" -Type String -Value "`"C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe`""
#Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Classes\CLSID\{00425F68-FFC1-445F-8EDF-EF78B84BA1C7}\LocalServer" -Name "(Default)" -Type String -Value "`"C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe`""

# Prevent Microsoft Outlook from being stuck at launch due to Teams meeting addin
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\Outlook\AddIns\TeamsAddin.FastConnect" -Name "Description" -Type String -Value "Microsoft Teams Meeting Add-in for Microsoft Office"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\Outlook\AddIns\TeamsAddin.FastConnect" -Name "LoadBehavior" -Type DWord -Value "3"
Set-RegistryKey -Key "HKLM:\DefaultUser\Software\Microsoft\Office\Outlook\AddIns\TeamsAddin.FastConnect" -Name "FriendlyName" -Type String -Value "Microsoft Teams Meeting Add-in for Microsoft Office"

# Unload the Default User registry hive
Execute-Process -Path "$envWinDir\System32\reg.exe" -Parameters "UNLOAD HKLM\DefaultUser" -WindowStyle Hidden

# Cleaup temp files
Remove-Item -Path "$envSystemDrive\Users\Default\*.LOG1" -Force
Remove-Item -Path "$envSystemDrive\Users\Default\*.LOG2" -Force
Remove-Item -Path "$envSystemDrive\Users\Default\*.blf" -Force
Remove-Item -Path "$envSystemDrive\Users\Default\*.regtrans-ms" -Force

Write-Log -Message "The default user profile was optimized!" -LogType 'CMTrace' -WriteHost $True