# AAD-RiskyUsers-Runbook Setup

## AzureAD App Registration

* Go to AzureAD / App Registration:
	* New Registration:
		* Name (e.g. "AADRiskyUsers")
		* Single Tenant
		* Redirect URI = "http://localhost"
		* Register!
		* Copy Application ID (aka "ClientID")
	* Certificates & Secrets:
		* New Client Secret:
			* Enter Description (e.g. "AADRiskyUsers")
			* Select lifetime (1 or 2 years, etc.)
		* Copy Secret to clipboard!
	* API Permissions:
		* Add a Permission > Microsoft.Graph:
			* Application Permissions:
				* IdentityRiskEvent (Read.All)
				* IdentityRiskyUser (Read.All)
				* Add Permissions!
			* Grant admin consent!

## Runbook Variables

* AAD-ClientID = (Azure AD Application Id)
* AAD-ClientSecret = (Azure AD Application Client Secret)
* AAD-ClientDomain = (Azure AD domain name)

## Runbook

* New Runbook
  * Type = PowerShell
  * Code = (copy/paste)
  
