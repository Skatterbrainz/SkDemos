<#
.SYNOPSIS Create Chrome Web Applications
.PARAMETER Location - Specify location for the shortcut
.PARAMETER URL - Specify the web apps URL
.PARAMETER Icon - Specify location for shortcut icon
.EXAMPLE - Create JoseEspitia.com web app in All Users start menu
New-ChromeWebApp -Location "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Jose Espitia.lnk" -URL https://www.JoseEspitia.com -Icon https://www.JoseEspitia.com/favicon.ico
.NOTES
Inspired heavily by https://www.joseespitia.com/2020/11/03/new-chromewebapp-function/?fbclid=IwAR1qfQYuyDbC8JZkiyGqeTDyw7GeMVzdJX8s0EMvsXp-oKYDlZVnTeRl5Hs
#>
[CmdletBinding()]
param (
    [parameter(Mandatory=$True)][string]$Location,
    [parameter(Mandatory=$True)][string]$URL,
    [parameter(Mandatory=$True)][string]$Icon
)
try {
  # Get Chrome.exe path
  $ChromeOpenCommand = (Get-ItemProperty Registry::HKCR\ChromeHTML\shell\open\command)."(Default)"
  $ChromeDefaultPath = $ChromeOpenCommand.Substring(0, $ChromeOpenCommand.IndexOf(' --'))
  $ChromeAppPath = $ChromeDefaultPath.substring(0,$ChromeDefaultPath.IndexOf("\chrome.exe"))
  Write-Verbose "chrome path = $ChromeAppPath"
  # Create web app shortcut
  $Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut("$Location")
  $Shortcut.TargetPath = "$ChromeDefaultPath"
  $Shortcut.Arguments = "--app=$URL"
  $Shortcut.WorkingDirectory = $ChromeAppPath
  $Shortcut.IconLocation = "$Icon"
  $Shortcut.Save()
}
catch {
  Write-Error $_.Exception.Message 
}
