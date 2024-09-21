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

Install-ChocolateyPackage -PackageName 'rabbitmq' -FileType 'exe' -SilentArgs '/S' -Url 'https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.5/rabbitmq-server-3.13.5.exe' -ChecksumType sha256 -Checksum cf8ce6c2ab6285eed65dd6c786cd433e90bfc54621451cea4a8b5c6a24c21a1d

$rabbitPath = Get-RabbitMQPath
if (-not $pp.ContainsKey('NOMANAGEMENT'))
{
    Start-Process -Verbose -FilePath "$rabbitPath\sbin\rabbitmq-plugins.bat" -ArgumentList 'enable','rabbitmq_management' -NoNewWindow -Wait
}
