<#
.SYNOPSIS
  Get recordings safe info for platforms, from policies.xml file.

.DESCRIPTION
  Takes policies.xml as input. Searches through and prints out platform ID's and the recordings safe info for each of them.
  If the SessionRecorderSafe value is empty, the platform has the default value (PSMRecordings)

.INPUTS
  Path to the Policies.xml file.

.OUTPUTS
  CSV file --> C:\Temp\platformsRecordingsInfo.csv

.EXAMPLE
  .\Get-PASPlatformRecordingsInfo.ps1 -XMLPath "C:\temp\Policies.xml"
#>

param(
  [Parameter(Mandatory)]
  [string]$XMLPath
)

$platformsRecordingsInfo = @()

[xml]$xmlPolicies = Get-Content -Path $XMLPath
$platforms = $xmlPolicies.PasswordVaultPolicies.Devices.Device.Policies.Policy

ForEach ($platform in $platforms) {
  $row = "" | Select-Object PlatformID,SessionRecorderSafe

  $row.PlatformID = $platform.ID
  $row.SessionRecorderSafe = $platform.PrivilegedSessionManagement.SessionRecorderSafe
  $platformsRecordingsInfo += $row
}

# Export output to csv
$platformsRecordingsInfo | Export-Csv -Path "C:\Temp\platformsRecordingsInfo.csv" -Delimiter ";"