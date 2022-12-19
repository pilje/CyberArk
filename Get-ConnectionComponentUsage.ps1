<#
.SYNOPSIS
  Check if a Connection Component is in use by one or more platforms. 

.DESCRIPTION
  Get a list of platforms using a specific Connection Component (CC). 
  Takes a CC ID (e.g PSM-RDP), searches through all active platforms listing those that have this CC configured.
  
  Uses the pspas powershell module: https://github.com/pspete/psPAS
  A valid pvwa session is required before running this script (see the pspas command New-PASSession)
  
.INPUTS
  ConnCompID : The ID for the connection component you want to check

.OUTPUTS
  Zero or more platforms using the specified CC.
  
      Platforms using the Connection Component PuTTY:

      PlatformID  CC    CCEnabled
      ----------  --    ---------
      UnixSSH     PuTTY     False
      UnixSSHKeys PuTTY     False
  
.EXAMPLE
  .\Get-ConnectionComponentsByPlatforms.ps1 -ConnCompID PSM-RDP
#>

param( 
  [Parameter(Mandatory)]
  [string]$ID
)

# REQUIRES A VALID SESSION TO PVWA (see https://github.com/pspete/psPAS for doc)
# New-PASSession -Credential $cred -BaseURI https://pvwa.somedomain.com -type LDAP

# Gets all active platforms 
$platforms = Get-PASPlatform -Active $true

$platformsUsingCC = @()

# Searched through each platform
foreach ($i in $platforms) {
    $connComponents = (Get-PASPlatformPSMConfig -ID $i.Details.ID).PSMConnectors

    If ($connComponents.Count -le 0) {
        continue
    }

    # Checks if specified CC exist in the list of all CC's in the platform
    If (($connComponents.PSMConnectorID).Contains($ConnCompID)) {
        $Row = "" | Select-Object PlatformID,CC,CCEnabled
        $Row.PlatformID = $i.PlatformID
        $Row.CC = $ConnCompID
        $Row.CCEnabled = ($connComponents | Where-Object {$_.PSMConnectorID -eq "$ConnCompID"}).Enabled
        $platformsUsingCC += $Row
    }
}

Write-Host "`nPlatforms using the Connection Component $($ConnCompID):"
$platformsUsingCC
