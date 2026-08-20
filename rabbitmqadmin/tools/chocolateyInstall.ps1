$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.34.0/rabbitmqadmin-2.34.0-x86_64-pc-windows-msvc.zip'
$checksum = '279b440610984d69d6a64804e8ae183d74a6112cdfb117815b07f975b4fc5571'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
