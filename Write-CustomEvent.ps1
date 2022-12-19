<#
.SYNOPSIS
  Script to write log event in Event Log with parameter.

.DESCRIPTION
  Write log events in specified Event Log, with multiple parameters.
  Modified from:
  https://kevinholman.com/2016/04/02/writing-events-with-parameters-using-powershell

.PARAMETER _
  [int]eventCode = Eventcode in event
  [String]log = Event log to write event to
  [string]source = Source of event
  [string]Type = INFORMATION, WARNING or ERROR
  [string]message = The first parameter (Eventdata > Data)
  [string]service = The second parameter (Eventdata > Data)

.OUTPUTS
  EventLog event (information, warning or error) in chosen event log.

.EXAMPLE
	.\Write-CustomEvent.ps1 -eventcode 1234 -log TestLog -source server01 -service service2 -message "This is not working" -Type INFORMATION
#>

Function Write-CustomEvent {
  [CmdletBinding()]
  param(
    [int]$eventCode,
    [String]$log = "PAMVault",
    [string]$source,
    [ValidateSet("INFORMATION","WARNING","ERROR")]
    [string]$Type,
    [string]$message,
    [string]$service
  )

  Switch ($Type) {
    "INFORMATION" { $entryType = 4 ; Break }
    "WARNING"     { $entryType = 2 ; Break }
    "ERROR"       { $entryType = 1 ; Break }
  }

  # Are not using category
  $category = 0

  $ID = New-Object System.Diagnostics.EventInstance($eventCode, $category, $entryType)
  $eventObject = New-Object System.Diagnostics.EventLog
  $eventObject.Log = $log
  $eventObject.Source = $source
  $eventObject.WriteEvent($ID, @($message,$service))
}