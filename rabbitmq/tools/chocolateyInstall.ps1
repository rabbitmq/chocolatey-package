. "$PSScriptRoot\ChocolateyHelpers.ps1"

$url = 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.3.6/rabbitmq-server-4.3.6.exe'
$checksum = '0f9ad1d87b8e81d1907a05e3003b154f886b959d01b9c108f9f0f9ea6b4b26b8'

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
