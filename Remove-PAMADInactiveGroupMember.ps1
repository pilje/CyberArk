<#
.SYNOPSIS
  Remove inactive AD Users from group X.

.DESCRIPTION
  Clean up AD Groups by removing inactive/disabled users from the group. 
  
.EXAMPLE
  .\Remove-InactiveADGroupMembers.ps1 -group "R-LicencedDUOUsers"
#>

# REQUIRES A VALID SESSION TO PVWA (see https://github.com/pspete/psPAS for doc)
# New-PASSession -Credential $cred -BaseURI https://pvwa.somedomain.com -type LDAP

param( 
  [Parameter(Mandatory)]
  [string]$group
)

$logFile = "C:\Powershell\Logs\Remove-InactiveADGroupMembers.txt"

# Helper function to write to logfile
function WriteLog {
  param(
    [string]$logStr
  )
  $time = (Get-Date).ToString("dd/MM/yyyy HH:mm")
  $logMsg = "$($time) $($logStr)"
  Add-Content $logFile -Value $logMsg
}

$disabledUsers = @()
$groupMembers = Get-ADGroupMember -Identity $group

foreach ($user in $groupMembers) {
  $disabled = 
    Get-ADUser -Identity $user.distinguishedName -Properties Enabled | 
    where-object {$_.Enabled -eq $false} | 
    Select-object SamAccountName,DistinguishedName,Enabled
  
  $disabledUsers += $disabled
}
WriteLog "INFO - Group $($group) $($disabledUsers.Count) disabled users to be removed: $($disabledUsers.SamAccountName)"

foreach ($user in $disabledUsers) {
  try {
    Remove-ADGroupMember -Identity $group -Members $user.distinguishedName -Confirm:$false        
  } catch {
    WriteLog "ERROR - failed to remove $($user.SamAccountName) from group $($group)"
  }  
}
