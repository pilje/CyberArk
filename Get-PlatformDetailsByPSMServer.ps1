<#
.SYNOPSIS
  Check if one or more platforms are using a specified PSM server / PSMVIP Server 

.DESCRIPTION
  Get a list of platforms configured to use the specified PSM Server / PSMVIP Server, 
  and the number of accounts associated with these platforms
  
  Uses the pspas powershell module: https://github.com/pspete/psPAS
  A valid pvwa session is required before running this script (see the pspas command New-PASSession)
  
.INPUTS
  PSMServer : The ID for the PSM Server or PSMVIP Server
  
.EXAMPLE
  .\Get-PlatformDetailsByPSMServer.ps1 -PSMServer PSM1
#>

param( 
  [Parameter(Mandatory)]
  [string]$PSMServer
)

# REQUIRES A VALID SESSION TO PVWA (see https://github.com/pspete/psPAS for doc)
# New-PASSession -Credential $cred -BaseURI https://pvwa.somedomain.com -type LDAP

# Gets all active platforms
$platforms = Get-PASPlatform -Active $true

$count = 0    # Number of platforms associated with this PSM Server
$table = @()  # Table containing all associated platforms, and the number of accounts in these platforms

foreach ($i in $platforms) {
    $psmPlatform = $i.PlatformID
    $psmVipServer = $i.Details.PrivilegedSessionManagement.PSMServerId

    if ($psmVipServer -like $PSMServer) {
        $count += 1

        # Number of accounts in each platform
        $numAccounts = 0
        $accounts = Get-PASAccount -search $psmPlatform
        
        forEach ($j in $accounts) {
            if ($j.platformId -like $psmPlatform) {
                $numAccounts += 1
            }
        }

        $obj = New-Object psobject -Property @{
            Platform = $psmPlatform
            PSMServer = $psmVipServer
            Num_Accounts = $numAccounts
        }

        $table += $obj | Select-Object Platform,PSMServer,Num_Accounts
    } 
}
$table


if ($count -like 0) {
    Write-Host "No platforms with ${PSMServer}`n" -ForegroundColor Yellow -
} else {
    Write-Host "Number of platforms with ${PSMServer}: ${count}`n" -ForegroundColor Green
}
