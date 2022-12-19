<#
.SYNOPSIS
  Sync an AD User to DUO, using DUO Admin API.

.DESCRIPTION
  Add or update an AD User to DUO. Requires a DUO MFA environment, and that the AD user to be synced is a member
  of the DUO sync group(s). 

  See https://duo.com/docs/adminapi for documentation on setting up DUO Admin API.
  
.EXAMPLE
  Sync-DUOUser -UserLogonName olaha
#>

function Sync-DUOUser() {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory)]
      [String]$UserLogonName
  )

  # API details (see https://duo.com/docs/adminapi for doc on how to find these parameters in your environment)
  $apiHostname = "api-1234.duosecurity.com"
  $sKey = Read-Host "Secret API key" 
  $iKey = "[integrationKey]"

  # Parameters specific for POST request user sync 
  # https://duo.com/docs/adminapi#synchronize-user-from-directory for directory key
  $method = "POST"
  $directoryKey = "[directory_key]" 
  $path = "/admin/v1/users/directorysync/" + $directoryKey + "/syncuser"
  $url = "https://" + $apiHostname + $path
  $date = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss -0000",([System.Globalization.CultureInfo]::InvariantCulture))

  # Parameters to send in the POST request
  $parameters = @{
    username = $UserLogonName
  }
  
  # Stringified parameters/URI Safe characters
  $stringAPIParams = ($parameters.Keys | Sort-Object | ForEach-Object {
    $_ + "=" + [uri]::EscapeDataString($parameters.$_)
  }) -join "&"

  # DUO parameters formatted and stored as bytes with StringAPIParams
  $DuoParams = (@(
      $date.Trim(),
      $method.ToUpper().Trim(),
      $apiHostname.ToLower().Trim(),
      $path.Trim(),
      $stringAPIParams.trim()
  ).trim() -join "`n").ToCharArray().ToByte([System.IFormatProvider]$UTF8)

  # Hash out secrets 
  $HMACSHA1 = [System.Security.Cryptography.HMACSHA1]::new($sKey.ToCharArray().ToByte([System.IFormatProvider]$UTF8))
  $HMACSHA1.ComputeHash($DuoParams) | Out-Null
  $ASCII = [System.BitConverter]::ToString($HMACSHA1.Hash).Replace("-", "").ToLower()

  # Create the new header and combing it with our iKey to use it as Authentication
  $AuthHeader = $iKey + ":" + $ASCII
  [byte[]]$ASCIIBytes = [System.Text.Encoding]::ASCII.GetBytes($AuthHeader)

  # Create our Parameters for the webrequest
  $DUOWebRequestParams = @{
      URI         = $url
      Headers     = @{
        "X-Duo-Date"    = $date
        "Authorization" = ('Basic: {0}' -f [System.Convert]::ToBase64String($ASCIIBytes))
      }
      Body        = $parameters
      Method      = $method
      ContentType = 'application/x-www-form-urlencoded'
  }

  Try {
    $send = Invoke-RestMethod @DUOWebRequestParams
    Write-Host "Synced user $UserLogonName in DUO."
  } catch {
    # If sync failes, wait 10 seconds and try again (typically happens with newly created users)
    Try {
      Start-Sleep 10
      $send = Invoke-RestMethod @DUOWebRequestParams
      Write-Host "Synced user $UserLogonName in DUO."
    } catch {
      Write-Warning "Automatic DUO sync of user $($UserLogonName) failed. DUO sync have to be initiated manually."
    }
  }
}
