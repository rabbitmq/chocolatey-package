if (!$PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

. "$PSScriptRoot\ChocolateyHelpers.ps1"

$pp = Get-PackageParameters

if ($pp['RABBITMQBASE'])
{
    [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $pp['RABBITMQBASE'], "Machine" )
    ${Env:RABBITMQ_BASE} = $pp['RABBITMQBASE']
}

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.7/rabbitmq-server-3.13.7.exe' -ChecksumType sha256 -Checksum 9813fc12cdb8769ddf6be9be2ee5607438051312221b883af980ee4ec629cdda

$rabbitPath = Get-RabbitMQPath
if (-not $pp.ContainsKey('NOMANAGEMENT'))
{
    Start-Process -Verbose -FilePath "$rabbitPath\sbin\rabbitmq-plugins.bat" -ArgumentList 'enable','rabbitmq_management' -NoNewWindow -Wait
}
