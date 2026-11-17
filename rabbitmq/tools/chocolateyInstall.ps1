. "$PSScriptRoot\ChocolateyHelpers.ps1"

$url = 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.4.1/rabbitmq-server-4.4.1.exe'
$checksum = 'ea01ad86e965ec070fdde6ffb61d429a7a6b4f9ed18b223fc10aa44e4f022e4c'

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
