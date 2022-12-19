<#
.SYNOPSIS
  Send a SMS using Link Mobility API.

.DESCRIPTION
  Send SMS using Link Mobility REST API.
  See https://linkmobility.no/utviklere/ for documentation on the [LINK SMS REST API (Send)]
  
.EXAMPLE
  Send-LinkRESTSMS -Phone 12345678 -Message "Hello you" 
#>

function Send-LinkRESTSMS {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [String]$Phone,

    [Parameter(Mandatory)]
    [String]$Message
  )

  # Trim whitespace from phone number, and add norwegian country code
  $Phone = $Phone.Replace(" ","")

  If (!$Phone.StartsWith("+")) {
    If ($Phone.Startswith("00")) {
      $Phone = $Phone.replace("00","+")
    } else {
      $Phone = $Phone.Insert(0,"+47")
    }
  }

  # API details (see documentation for info --> These details are personal)
  $url = "https://n-eu.linkmobility.io/sms/send"
  $user = "[APIusername]"
  $credential = Get-Credential -credential $user

  $body = @{
    "source"            = "Sender"         # Sender Display name in the SMS
    "destination"       = $Phone            
    "userData"          = "$Message"
    "platformId"        = "COMMON_API"
    "platformPartnerId" = "[1234]"
    "useDeliveryReport" = $false
  }

  try {
    Invoke-RestMethod -Method 'Post' -Uri $url -Credential $credential -Body ($body | ConvertTo-Json) -ContentType 'application/json'
  }
  catch {
    Write-Warning "Sending SMS failed."
  }
}
