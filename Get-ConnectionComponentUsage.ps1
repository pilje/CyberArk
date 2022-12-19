<#
.SYNOPSIS
  Check if a Connection Component is in use by one or more platforms. 

.DESCRIPTION
  Get a list of platforms that are using a specific Connection Component (CC). 
  Takes a CC ID (e.g NHN-SPLUNK-EXT) as input, 
  searches through all active platforms listing those that have this CC configured.

.OUTPUTS
  Zero or more platforms using the specified CC.
#>

# ID PÅ CONNECTION COMPONENT MAN ØNSKER Å SJEKKE 
$connCompName = "PuTTY" 

# REQUIRES A VALID SESSION TO PVWA 
#New-NHNPASSession -credential (get-credential sa_pam_api)

# Henter ut alle aktive plattformer
$platforms = Get-PASPlatform -Active $true

$platformsUsingCC = @()

# Søker gjennom hver plattform
foreach ($i in $platforms) {
    #Write-Host "------------------------------------"
    #write-host "`Searching throuh platform $($i.PlatformID)"
    $connComponents = (Get-PASPlatformPSMConfig -ID $i.Details.ID).PSMConnectors

    If ($connComponents.Count -le 0) {
        continue
    }

    # Sjekker om spesifisert CC finnes i listen over CC'er på plattformen
    If (($connComponents.PSMConnectorID).Contains($connCompName)) {
        $Row = "" | Select-Object PlatformID,CC,CCEnabled
        $Row.PlatformID = $i.PlatformID
        $Row.CC = $connCompName
        $Row.CCEnabled = ($connComponents | Where-Object {$_.PSMConnectorID -eq "$connCompName"}).Enabled
        $platformsUsingCC += $Row
    } else {
        #Write-Host "Platform $($i.PlatformID) har IKKE $connCompName." -ForegroundColor yellow
    }   
}

Write-Host "`nPlatforms that are using the Connection Component $($connCompName):"
$platformsUsingCC


# OUTPUT:
#
# PS D:\Gitlab_ID\snippets> . 'd:\Gitlab_ID\snippets\Cyberark_pspas\Get-ConnectionComponentsByPlatforms.ps1'
# 
# Platforms that are using the Connection Component PuTTY:
#
# PlatformID  CC    CCEnabled
# ----------  --    ---------
# UnixSSH     PuTTY     False
# UnixSSHKeys PuTTY     False