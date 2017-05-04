if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\ChocolateyHelpers.ps1"

$arguments = Get-ChocolateyPackageParameters ${Env:ChocolateyPackageParameters}

if ($arguments['RABBITMQBASE']) {
  [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $arguments['RABBITMQBASE'], "Machine" )
  ${Env:RABBITMQ_BASE} = $arguments['RABBITMQBASE']
}

Install-ChocolateyPackage 'rabbitmq' 'EXE' '/S' 'https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_9/rabbitmq-server-3.6.9.exe'

$rabbitPath = Get-RabbitMQPath
if (-not $arguments.ContainsKey('NOMANAGEMENT')) {
  Start-Process "$rabbitPath\sbin\rabbitmq-service.bat" 'enable rabbitmq_management --offline' -NoNewWindow -Wait
  Start-Process "$rabbitPath\sbin\rabbitmq-plugins.bat" 'enable rabbitmq_management' -NoNewWindow -Wait
}

Start-Process "$rabbitPath\sbin\rabbitmq-service.bat" 'install' -NoNewWindow -Wait
