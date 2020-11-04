<#
.SYNOPSIS Create Microsoft Chromium Edge Web Applications
.PARAMETER Location - Specify location for the shortcut
.PARAMETER URL - Specify the web apps URL
.PARAMETER Icon - Specify location for shortcut icon
.EXAMPLE - Create JoseEspitia.com web app in All Users start menu
New-EdgeWebApp -Location "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Jose Espitia.lnk" -URL https://www.JoseEspitia.com -Icon https://www.JoseEspitia.com/favicon.ico
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
  # Get msedge.exe path
  $EdgeOpenCommand = (Get-ItemProperty Registry::HKCR\MSEdgeHTM\shell\open\command)."(Default)"
  $EdgeDefaultPath = $EdgeOpenCommand.Substring(0, $EdgeOpenCommand.IndexOf(' --'))
  $EdgeAppPath = $EdgeDefaultPath.substring(0,$EdgeDefaultPath.IndexOf("\msedge.exe"))
  Write-Verbose "edge path = $EdgeAppPath"
  # Create web app shortcut
  $Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut("$Location")
  $Shortcut.TargetPath = "$EdgeDefaultPath"
  $Shortcut.Arguments = "--app=$URL"
  $Shortcut.WorkingDirectory = $EdgeAppPath
  $Shortcut.IconLocation = "$Icon"
  $Shortcut.Save()
}
catch {
  Write-Error $_.Exception.Message 
}
