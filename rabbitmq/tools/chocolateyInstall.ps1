. "$PSScriptRoot\ChocolateyHelpers.ps1"

$url = 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.3.5/rabbitmq-server-4.3.5.exe'
$checksum = 'e7f8a8dc326714ca5b964e27f987b020398a4a3f4b52c4d85d8f342b0b0e4e7d'

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
