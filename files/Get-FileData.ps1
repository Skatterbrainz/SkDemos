[CmdletBinding()]
param (
	[parameter(Mandatory)][ValidateRange(1,7)][int] $Test
)

switch ($Test) {
	1 {
		$testFile = ".\sample.txt"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import TXT data")
		$txtData = Get-Content $testfile 
		$txtData
	}
	2 {
		$testFile = ".\sample.txt"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import tab-delimited TXT data")
		$tabData = Import-Csv -Path $testFile -Delimiter "`t"
		$tabData
	}
	3 {
		$testFile = ".\sample.xml"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import XML data")
		[xml]$xmlData = Get-Content $testfile
		$xmlData.Start.Operation
	}
	4 {
		$testFile = ".\sample.json"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import JSON data")
		$jdata = $(Get-Content -Path $testFile | ConvertFrom-Json).psobject.Properties | ForEach-Object {$_.Value}
		$jdata
	}
	5 {
		$testFile = ".\sample.csv"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import CSV text data")
		$csvdata = Import-Csv -Path $testFile
		$csvdata
	}
	6 {
		$testFile = ".\sample.ini"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import INI text data")
		$iniData = Get-IniContent -FilePath $testFile
		$iniData 
	}
	7 {
		$testFile = ".\sample.xlsx"
		if (!(Test-Path $testFile)) { throw "file not found: $testFile" }
		[console]::WriteLine("Import Microsoft Excel worksheet data")
		$xlData = Import-Excel -Path $testFile -WorksheetName "Employees"
		$xlData
	}
}
