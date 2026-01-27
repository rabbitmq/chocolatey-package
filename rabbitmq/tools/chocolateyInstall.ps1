. "$PSScriptRoot\ChocolateyHelpers.ps1"

$url = 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.2.3/rabbitmq-server-4.2.3.exe'
$checksum = '743d6bd70961f58ac53a539399702708e4193f15b47b96a2d8c051ce74d8dac8'

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
