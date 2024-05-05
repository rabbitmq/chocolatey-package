if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\ChocolateyHelpers.ps1"

$arguments = Get-ChocolateyPackageParameters ${Env:ChocolateyPackageParameters}

if ($arguments['RABBITMQBASE']) {
  [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $arguments['RABBITMQBASE'], "Machine" )
  ${Env:RABBITMQ_BASE} = $arguments['RABBITMQBASE']
}

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.14/rabbitmq-server-3.12.14.exe' -ChecksumType sha256 -Checksum c47659d4d0307ad156cee57eb98831913bd77d2726febf8ba4a536a35395dd7e

$rabbitPath = Get-RabbitMQPath
if (-not $arguments.ContainsKey('NOMANAGEMENT')) {
  Start-Process "$rabbitPath\sbin\rabbitmq-plugins.bat" 'enable rabbitmq_management' -NoNewWindow -Wait
}
