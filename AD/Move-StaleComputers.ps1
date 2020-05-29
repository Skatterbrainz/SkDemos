function Get-DomainComputers {
	[CmdletBinding()]
	param()
	$comps = Get-ADComputer -Filter * -Properties operatingSystem,lastLogonTimestamp,whenCreated
	$comps | ForEach-Object {
		[datetime]$created = ($_.whenCreated | Out-String).Trim()
		$llogon = ([datetime]::FromFiletime(($_.lastlogonTimeStamp | Out-String).Trim()))
		$age = (New-TimeSpan -Start $llogon -End (Get-Date)).Days
		[pscustomobject]@{
			Name = $_.Name
			DistinguishedName = $_.DistinguishedName
			OperatingSystem = $_.operatingSystem
			DNSHostName = $_.DNSHostName
			Enabled     = $_.Enabled
			ObjectGUID  = $_.ObjectGUID
			SID         = ($_.SID).ToString()
			DateCreated = $created
			LastLogon   = $llogon
			Age         = $age
		}
	}
}

function Move-StaleADComputers {
	[CmdletBinding()]
	param (
		[parameter()][int] $MaxDaysOld = 30,
		[parameter()][ValidateNotNullOrEmpty()][string] $OuDisabled = "OU=DisabledComputers,OU=CORP,DC=contoso,DC=local",
		[parameter()][pscredential] $Credential
	)
	$ErrorActionPreference = "stop"
	try {
		$allComps = Get-DomainComputers
		Write-Verbose "returned $($allComps.Count) total computer accounts"

		$staleCrap = Get-DomainComputers | Where-Object {$_.Age -gt $MaxDaysOld}
		Write-Verbose "returned $($staleCrap.Count) stale computer accounts"

		$msgbody = "<h2>Stale Computer Accounts (over $MaxDaysOld days)</h2> <table width=600 border=1>"
		$msgbody += "<tr><th>Name</th><th>OperatingSystem</th><th>LastLogon</th><th>GUID</th></tr>"
		$mcount = 0
		$staleCrap | %{ 
			Write-Verbose "moving computer: $($_.Name) [$($_.ObjectGUID)]"
			$msgbody += "<tr><td>$($_.Name)</td><td>$($_.OperatingSystem)</td><td>$($_.LastLogon)</td><td>$($_.ObjectGUID)</td></tr>"
			Move-ADObject $_.ObjectGUID -TargetPath $OUDisabled -Credential $ADCred
			Write-Verbose "disabling account"
			Disable-ADAccount -Identity $_.ObjectGUID -Credential $ADCred
			Write-Verbose "setting account description to indicate process date"
			Set-ADComputer -Identity $_.ObjectGUID -Description "moved and disabled: $(Get-Date -f 'MM/dd/yyyy')" -Credential $ADCred | Out-Null
			$mcount++
		}
		$msgbody += "</table> <p>Total stale accounts: $mcount</p>"

		$result = @{
			Status        = 'Success'
			StaleAccounts = $staleCrap.Count
			MovedAccounts = $mcount
			ReportBody    = $msgbody
		}
	}
	catch {
		$result = @{
			Status        = 'Failed'
			StaleAccounts = $staleCrap.Count
			MoveAccounts  = $mcount
			ErrorMsg      = "$($_.Exception.Message -join ';')"
		}
	}
	finally {
		Write-Output $result
	}
}


