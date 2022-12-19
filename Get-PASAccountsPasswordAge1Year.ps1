<#
.SYNOPSIS
  List accounts where password change is more than 1 year

.DESCRIPTION
  Get a list of accounts with password older than 1 year.  

  Uses the psPAS powershell module: https://github.com/pspete/psPAS
  A valid pvwa session is required before running this script (see the psPAS command New-PASSession)
  
.OUTPUTS
  CSV file containing the accounts
  
.EXAMPLE
  .\Get-PASAccountsPasswordAge1Year.ps1
#>

# REQUIRES A VALID SESSION TO PVWA (see https://github.com/pspete/psPAS for doc)
# New-PASSession -Credential $cred -BaseURI https://pvwa.somedomain.com -type LDAP

# Helper function to convert from UnixTime to human time
Function Convert-FromUnixDate($UnixDate) {
   $date = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
   $date.ToString("dd/MM/yyyy")
}

# Find the Unix date 1 year ago
$unixDateStart = Get-Date -Date "01/01/1970"
$date1YearAgo = (Get-Date).AddDays(-365)
$date1YearAgoUnix = (New-TimeSpan -Start $unixDateStart -End $date1YearAgo).TotalSeconds

# Accounts where password is older than 1 year
$accountsWithOldPassword = 
    Get-PASAccount | 
    Where-Object {$_.secretmanagement.lastModifiedTime -lt $date1YearAgoUnix} | 
    Select-Object -Property userName, platformId, address, @{name='PasswordLastChanged';E={Convert-FromUnixDate($_.secretManagement.lastModifiedTime)}} 

# Export output to csv
$accountsWithOldPassword | Export-Csv -Path "C:\Temp\UsersPassword1YearAgo.csv"
