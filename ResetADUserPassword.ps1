<#
.SYNOPSIS
  Reset an AD Users password, and send a new one on SMS using the [LINK SMS REST API] - Send-LinkRESTSMS.ps1

.DESCRIPTION
  Resets an AD Users password, and sends the new password to the user by SMS (according to details stored in the AD User object)
  Uses the function Send-LinkRESTSMS (see the file Send-LinkRESTSMS.ps1)
  
.EXAMPLE
  ResetADUserPassword -UserLogonName olaha
#>


function ResetADUserPassword() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [String]$UserLogonName,

    [Parameter()]
    [String]$InputPassword,

    [Parameter()]
    [Switch]$ReportMode
  )

  # Script variables
  $baseOUPath = "OU=Users,OU=Company,$((Get-ADDomain -ErrorAction stop).DistinguishedName)"
  $actualuser = $null
  $Password = ""

  # Tries to find an AD user with username [UserLogonName] 
  # Searched through OU=Users,OU=Company
  $actualUser = Get-ADUser -filter "SamAccountName -eq '$UserLogonName'" -SearchBase $baseOUPath -Properties SamAccountName,Mobile,Enabled -ErrorAction Stop
  if ($null -eq $actualUser) {
    throw "Couldn't find user $UserLogonName in $baseOUPath."
  }

  # Exits further running of the script if the user is disabled
  if (!$actualUser.Enabled) {
    Write-Error "User $($actualUser.SamAccountName) is disabled. The user must be enabled."
    exit
  }
  
  # Generates a password for the AD user
  if ([string]::IsNullOrEmpty($InputPassword)) {
    $chars = [Char[]]"abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ123456789"
    $Password = ($chars | get-random -Count 13) -join ""
    $Password = $Password + "cJ5!"
  } else {
    $Password = $InputPassword
  }

  # Sets new password on the AD user
  if (!$ReportMode) {
    try {
      $actualUser | Set-ADAccountPassword -Reset -NewPassword ((ConvertTo-SecureString -String $Password -AsPlainText -Force)) -ErrorAction Stop
    }
    catch {
      throw "Failed to set a new password for user $($actualUser.SamAccountName). `r`n
      $_.Exception.message "
    }
  } else {
    Write-Host "REPORT MODE ---- Sets new password for user $($actualUser.SamAccountName) to $Password"
  }
  
  # Sends new password on SMS
  if (!$ReportMode) {
    Send-LinkRESTSMS -Message $Password -Phone $($actualUser.Mobile)
  } else {
    Write-Host "REPORT MODE ---- Password have to be sent manually to $($actualUser.Mobile). Password: " -f white -n; Write-Host "$Password" -f yellow
  }
}
