Write-Output "***** Starting PSWindowsUpdate Installation"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force

if (Get-ChildItem "C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate") {
    Write-Output "***** PSWindowsUpdate installed successfully"
}

Write-Output "***** Starting Windows Update Installation"

Try
{
    Import-Module PSWindowsUpdate -ErrorAction Stop
}
Catch
{
    Write-Error "***** Unable to Import PSWindowsUpdate"
    exit 1
}

Import-Module PSWindowsUpdate

Get-WUInstall -AcceptAll -Install -IgnoreReboot | Out-File C:\Windows\Temp\PSWindowsUpdate.log

Write-Output "***** Ended Windows Update Installation"