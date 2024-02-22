if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\ChocolateyHelpers.ps1"

$arguments = Get-ChocolateyPackageParameters ${Env:ChocolateyPackageParameters}

if ($arguments['RABBITMQBASE']) {
  [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $arguments['RABBITMQBASE'], "Machine" )
  ${Env:RABBITMQ_BASE} = $arguments['RABBITMQBASE']
}

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.0/rabbitmq-server-3.13.0.exe' -Checksum 'A3B1B54D4105BBA33CCEFC8EAD7CA10C0087148F1ED29B7FF9A39476501354FF'

$rabbitPath = Get-RabbitMQPath
if (-not $arguments.ContainsKey('NOMANAGEMENT')) {
  Start-Process "$rabbitPath\sbin\rabbitmq-plugins.bat" 'enable rabbitmq_management' -NoNewWindow -Wait
}
