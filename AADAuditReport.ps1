PARAM ($PastDays = 7, $PastHours )
#************************************************
# AADAuditReport.ps1
# Version 1.0
# Date: 4-12-2016
# Author: Tim Springston
# Description: This script will search an Azure AD tenant which has Azure AD Premium licensing and AAD Auditing enabled 
#  using GraphApi for audit results for a specified period till current time. At least one
#  user must be assigned an AAD Premium license for this to work.
# Results are placed into a CSV file for review.
#************************************************
cls

$7daysago = "{0:s}" -f (get-date).AddDays(-7) + "Z"
if ($PastHours -gt 0)
	{
	$Date = Get-Date
	$PastPeriod = "{0:s}" -f (Get-Date).AddHours(-($PastHours)) + "Z"
	$TimePeriodStatement = " past $PastHours hours. Current time is $Date`."
	}
	else
		{
		$DateRaw = Get-Date
		$Date = ($DateRaw.Month.ToString()) + '-' + ($DateRaw.Day.ToString()) + "-" + ($DateRaw.Year.ToString())
		$PastPeriod =  "{0:s}" -f (get-date).AddDays(-($PastDays)) + "Z"
		$TimePeriodStatement = " past $PastDays days priot to $Date`."
		}
	
# This script will require the Web Application and permissions setup in Azure Active Directory
$ClientID       = "insert GUID here"             # Should be a ~35 character string insert your info here
$ClientSecret   = "insert secret here"         # Should be a ~44 character string insert your info here
$loginURL       = "https://login.windows.net"
$tenantdomain   = "insert tenant name here"            # For example, contoso.onmicrosoft.com
$AuditOutputCSV = $Pwd.Path + "\" + (($tenantdomain.Split('.')[0]) + "_AuditReport.csv")
# Get an Oauth 2 access token based on client id, secret and tenant domain
$body       = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth      = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body

Write-Output "Searching the tenant $tenantdomain for AAD audit events for the $TimePeriodStatement"

if ($oauth.access_token -ne $null) {
    $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
	$URIfilter = "`$filter=eventTime gt $PastPeriod"
    $url = "https://graph.windows.net/$tenantdomain/reports/auditEvents?api-version=beta&"  + $URIfilter

    $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
	$ConvertedReport = ConvertFrom-Json -InputObject $myReport.Content 
	$XMLReportValues = $ConvertedReport.value
	$XMLReportValues | select *  |  Export-csv $AuditOutputCSV -NoTypeInformation -Force -append

	Write-Host "Report complete. The CSV result can be found at $AuditOutputCSV`."
		} 
		else 
		{Write-Host "ERROR: No Access Token"}
