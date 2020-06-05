#Requires -Module dbatools
<#
.SYNOPSIS
	Query ConfigMgr site database using store query files
.DESCRIPTION
	Query ConfigMgr site database using store query files
.PARAMETER QueryFilesPath
	Path to stored query files (.sql extension)
.PARAMETER QueryFile
	Path to specific query file (overrides gridview selection)
.PARAMETER SQLHostName
	Hostname of SQL instance
.PARAMETER Database
	Database name
.EXAMPLE
	Get-CmDbQuery.ps1 -SQLHostName "cm01.contoso.local" -Database "CM_P01" -QueryFilesPath "x:\shared\queries"
	Displays a GridView selection list of query files to choose from, then submits to SQL server instance
.EXAMPLE
	Get-CmDbQuery.ps1 -SQLHostName "cm01.contoso.local" -Database "CM_P01" -QueryFile "x:\shared\queries\clients.sql"
	submits query file to SQL server instance directly
.OUTPUTS
	Array of records (objects)
.NOTES
	20.06.05 - David Stein
#>
[CmdletBinding()]
param (
	[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $SQlHostName,
	[parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Database,
	[parameter()][string] $QueryFilesPath = "",
	[parameter()][string] $QueryFile = ""
)

try {
	if ([string]::IsNullOrEmpty($QueryFile)) {
        Write-Verbose "looking for files in $QueryFilesPath"
		if ([string]::IsNullOrEmpty($QueryFilesPath)) { throw "no path specified" }
		$qfiles = @(Get-ChildItem -Path $QueryFilesPath -Filter "*.sql")
		if ($qfiles.Count -eq 0) { throw "No query files found in path: $QueryFilesPath" }
		$qfile = $qfiles | Select-Object Name,FullName | 
			Sort-Object Name | 
				Out-GridView -Title "Select Query to Run" -OutputMode Single
	} else {
		if (-not(Test-Path $QueryFile)) { throw "File not found: $QueryFile" }
		$qfile = Get-Item -Path $QueryFile
	}
	if ($null -ne $qfile) {
		Write-Verbose "submitting query from file: $($qfile.FullName)"
		@(Invoke-DbaQuery -SqlInstance $SQLHostName -Database $Database -File $qfile.FullName)
	}
}
catch {
	$msg = $_.Exception.Message
	if ($msg -match 'No query files found') {
		Write-Warning $msg 
	} else {
		Write-Error $msg 
	}
}
