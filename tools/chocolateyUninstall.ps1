if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\ChocolateyHelpers.ps1"

$rabbitPath = Get-RabbitMQPath

Start-Process -Wait "$rabbitPath\..\uninstall" "/S"

$erlangKey = "HKLM:\SOFTWARE\Ericsson\Erlang\ErlSrv\1.1\RabbitMQ"
if (Test-Path $erlangKey) {
  Get-Process | Where-Object {$_.ProcessName -like "*erl*"} | Stop-Process -Force
  Remove-Item $erlangKey
}