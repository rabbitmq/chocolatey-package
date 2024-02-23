﻿if (!$PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

. "$PSScriptRoot\ChocolateyHelpers.ps1"

$arguments = Get-ChocolateyPackageParameters ${Env:ChocolateyPackageParameters}

if ($arguments['RABBITMQBASE'])
{
  [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $arguments['RABBITMQBASE'], "Machine" )
  ${Env:RABBITMQ_BASE} = $arguments['RABBITMQBASE']
}

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.0/rabbitmq-server-3.13.0.exe' -ChecksumType sha256 -Checksum a3b1b54d4105bba33ccefc8ead7ca10c0087148f1ed29b7ff9a39476501354ff

$rabbitPath = Get-RabbitMQPath
if (-not $arguments.ContainsKey('NOMANAGEMENT'))
{
    Start-Process -WhatIf -FilePath "$rabbitPath\sbin\rabbitmq-plugins.bat" -ArgumentList 'enable','rabbitmq_management' -NoNewWindow -Wait
    Start-Process -FilePath "$rabbitPath\sbin\rabbitmq-plugins.bat" -ArgumentList 'enable','rabbitmq_management' -NoNewWindow -Wait
}
