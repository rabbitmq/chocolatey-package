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

# https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.x.y/rabbitmq-server-4.x.y.exe
Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v4.0.6/rabbitmq-server-4.0.6.exe' -ChecksumType sha256 -Checksum 8341196090B1CF705B5D21EBB73F9CAE9BEA6F7362DC7E846594CA8428592D06
$rabbitPath = Get-RabbitMQPath
if (-not $pp.ContainsKey('NOMANAGEMENT'))
{
    Start-Process -Verbose -FilePath "$rabbitPath\sbin\rabbitmq-plugins.bat" -ArgumentList 'enable','rabbitmq_management' -NoNewWindow -Wait
}
