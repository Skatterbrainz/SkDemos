[CmdletBinding()]
param ()

if ((Get-WindowsOptionalFeature -online -FeatureName Containers-DisposableClientVM).State -eq 'Disabled') {
    Write-Host "enabling sandbox support features"
    Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM
} else {
    Write-Host "sandbox support features are already enabled"
}

$sbConfigXML = @"
<Configuration>
    <MappedFolders>
        <MappedFolder>
        <!-- Create a drive mapping that mirrors my Scripts folder -->
            <HostFolder>C:\scripts</HostFolder>
            <SandboxFolder>C:\scripts</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
         <MappedFolder>
            <HostFolder>C:\Pluralsight</HostFolder>
            <SandboxFolder>C:\Pluralsight</SandboxFolder>
            <ReadOnly>true</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <ClipboardRedirection>true</ClipboardRedirection>
    <MemoryInMB>8096</MemoryInMB>
    <LogonCommand>
     <Command>C:\scripts\sandbox-setup.cmd</Command>
    </LogonCommand>
</Configuration>
"@

$logon = @"
REM sandbox-setup.cmd
REM This code runs in the context of the Windows Sandbox
REM Create my standard Work folder
mkdir c:\work
 
REM set execution policy first so that a setup script can be run
powershell.exe -command "&{Set-ExecutionPolicy RemoteSigned -force}"
 
REM Now run the true configuration script
powershell.exe -file c:\scripts\sandbox-config.ps1
"@

$sbConfigPS = @"
Enable-PSRemoting -force -SkipNetworkProfileCheck
 
Install-PackageProvider -Name nuget -Force -ForceBootstrap -Scope AllUsers
Update-Module PackageManagement,PowerShellGet -force
 
#run updates and installs in the background
Start-Job {Install-Module PSScriptTools,PSTeachingTools -Force}
Start-Job {Install-Module PSReleaseTools -Force; Install-PowerShell -Mode Quiet -EnableRemoting -EnableContextMenu}
Start-Job {Install-Module WTToolbox -Force ; Install-WTRelease}
Start-Job -FilePath c:\scripts\install-vscodesandbox.ps1
Start-Job -FilePath c:\scripts\Set-SandboxDesktop.ps1
 
#wait for everything to finish
Get-Job | Wait-Job
"@

#

$vsCodeInstall = @"
$file = Join-Path -path $env:temp -child 'VSCodeSetup-x64.exe'
Invoke-WebRequest -Uri "https://update.code.visualstudio.com/latest/win32-x64-user/stable" -OutFile $file -DisableKeepAlive -UseBasicParsing
 
$loadInf = '@
[Setup]
Lang=english
Dir=C:\Program Files\Microsoft VS Code
Group=Visual Studio Code
NoIcons=0
Tasks=desktopicon,addcontextmenufiles,addcontextmenufolders,addtopath
@'
 
$infPath = Join-Path -path $env:TEMP -child load.inf
$loadInf | Out-File $infPath
 
Start-Process -FilePath $file -ArgumentList "/VERYSILENT /LOADINF=${infPath}" -Wait
 
#add extensions
Start-Process -filepath "C:\Program Files\Microsoft VS Code\bin\code.cmd" -ArgumentList "--install-extension ms-vscode.powerShell"
"@

#

$customSetup = @'
# Set-SandboxDesktop.ps1
# my Pluralsight related configuration
 
function Update-Wallpaper {
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0,HelpMessage="The path to the wallpaper file.")]
        [alias("wallpaper")]
        [ValidateScript({Test-Path $_})]
        [string]$Path = $(Get-ItemPropertyValue -path 'hkcu:\Control Panel\Desktop\' -name Wallpaper)
    )
 
    Add-Type @"
 
    using System;
    using System.Runtime.InteropServices;
    using Microsoft.Win32;
 
    namespace Wallpaper
    {
        public class UpdateImage
        {
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
 
            private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
 
            public static void Refresh(string path)
            {
                SystemParametersInfo( 20, 0, path, 0x01 | 0x02 );
            }
        }
    }
"@
 
    if ($PSCmdlet.shouldProcess($path)) {
        [Wallpaper.UpdateImage]::Refresh($Path)
    }
}
 
#configure the taskbar and hide icons
 
if (-not (Test-Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer)) {
    [void](New-Item hkcu:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer)
}
 
Set-ItemProperty hkcu:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ -Name Hideclock -Value 1
Set-ItemProperty hkcu:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ -Name HideSCAVolume -Value 1
Set-ItemProperty hkcu:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\ -Name HideSCANetwork -Value 1
 
if (-not (Test-Path hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced)) {
    [void](New-Item hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced)
}
 
Set-ItemProperty hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideIcons -Value 1
 
#configure wallpaper
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -name Wallpaper -Value C:\Pluralsight\Wallpaper\Pluralsight_Wallpaper_Fall_2015_Black.jpg
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -name WallpaperOriginX -value 0
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -name WallpaperOriginY -value 0
Set-ItemProperty 'hkcu:\Control Panel\Desktop\' -name WallpaperStyle -value 10
 
Update-WallPaper
 
<# This doesn't work completely in newer versions of Windows 10 Invoke-Command {c:\windows\System32\RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters 1,True} #>
#this is a bit harsh but it works
Get-Process explorer | Stop-Process -force
'@

Function Start-WindowsSandbox {
    [cmdletbinding(DefaultParameterSetName = "config")]
    [alias("wsb")]
    Param(
        [Parameter(ParameterSetName = "config")]
        [ValidateScript({Test-Path $_})]
        [string]$Configuration = "C:\scripts\WinSandBx.wsb",
        [Parameter(ParameterSetName = "normal")]
        [switch]$NoSetup
    )

    Write-Verbose "Starting $($myinvocation.mycommand)"

    if ($NoSetup) {
        Write-Verbose "Launching default WindowsSandbox.exe"
        c:\windows\system32\WindowsSandbox.exe
    }
    else {
        Write-Verbose "Launching WindowsSandbox using configuration file $Configuration"
        Invoke-Item $Configuration
    }

    Write-Verbose "Ending $($myinvocation.mycommand)"
}