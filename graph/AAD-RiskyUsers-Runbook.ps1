<#
.SYNOPSIS
	Retrieve Risky Users from Azure AD tenant
.DESCRIPTION
	Yeah, what he just said
.PARAMETER none
.EXAMPLE 
	Refer to the markdown help file
.NOTES
	Adapted the bulk of code from https://gist.github.com/mrik23/5661ff3f31ff13ab5610fb900ff6e92a
	Instructions for Azure AD app registration thanks to Scott Corio @ScottCorio 
.INPUTS
	none
.OUTPUTS
	Array of custom objects (hash tables)
#>
[CmdletBinding()]
param ()

$ClientID = Get-AutomationVariable -Name 'AAD-ClientID'
$ClientSecret = Get-AutomationVariable -Name 'AAD-ClientSecret'
$Domain = Get-AutomationVariable -Name 'AAD-ClientDomain'
$graphApiVersion = "beta"

$loginURL = "https://login.microsoft.com"
$resource = "https://graph.microsoft.com"
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}

try {
	Write-Verbose "requesting oauth token"
	$oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$Domain/oauth2/token?api-version=$graphApiVersion" -Body $body

	if ($null -ne $oauth.access_token) {
		
		Write-Verbose "requesting graph data"
		$headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}

		[uri]$uriGraphEndpoint = "https://graph.microsoft.com/beta/riskDetections"

		$response = Invoke-RestMethod -Method Get -Uri $uriGraphEndpoint.AbsoluteUri -Headers $headerParams

		$result = @()
		if ($null -ne $response.value) {
			$sortedResponses = $response.value | Sort-Object activityDateTime -Descending
			foreach ( $event in $sortedResponses ) {
				$result += [pscustomobject]@{
					DisplayName = $($event.userDisplayName)
					UPN         = $($event.userPrincipalName)
					EventTime   = $($event.activityDateTime)
					RiskType    = $($event.riskEventType)
					RiskState   = $($event.riskState)
					IPAddress   = $($event.ipAddress)
					Location    = $($event.location)
				}
			}
		} else {
			$result = "No risky detections found"
		}
	} else {
		throw "ERROR: No Access Token"
	}
}
catch {
	Write-Error $_.Exception.Message
}
finally {
	$result
}