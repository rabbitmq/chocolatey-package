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

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.2/rabbitmq-server-3.13.2.exe' -ChecksumType sha256 -Checksum a5265e7813a05a6c9bd225e6efef02a050fe7ef1fa04337d50ebc25c5b98338e

$rabbitPath = Get-RabbitMQPath
if (-not $pp.ContainsKey('NOMANAGEMENT'))
{
    Start-Process -Verbose -FilePath "$rabbitPath\sbin\rabbitmq-plugins.bat" -ArgumentList 'enable','rabbitmq_management' -NoNewWindow -Wait
}
