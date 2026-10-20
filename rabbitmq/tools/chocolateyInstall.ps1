. "$PSScriptRoot\ChocolateyHelpers.ps1"

$url = 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.4.0/rabbitmq-server-4.4.0.exe'
$checksum = 'aedcc039f02f0a46a223af00e2553955af8935aa9636608d54b811fb94edff06'

$pp = Get-PackageParameters

if ($pp['RABBITMQBASE'])
{
    [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $pp['RABBITMQBASE'], "Machine")
    ${Env:RABBITMQ_BASE} = $pp['RABBITMQBASE']
}

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url $url -ChecksumType 'sha256' -Checksum $checksum

$rabbitPath = Get-RabbitMQPath
if ($pp.ContainsKey('NOMANAGEMENT'))
{
    Write-Output '[INFO] RabbitMQ installation completed.'
}
else
{
    Write-Output '[INFO] RabbitMQ installation completed, enabling rabbitmq_management plugin...'
    & "$rabbitPath\sbin\rabbitmq-plugins.bat" enable rabbitmq_management
    Write-Output '[INFO] rabbitmq_management plugin is enabled.'
}
