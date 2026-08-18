$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.33.0/rabbitmqadmin-2.33.0-x86_64-pc-windows-msvc.zip'
$checksum = '26daecb340986665611fd13cc963b5ae27a8172d0b6429130662b9ad1bd55267'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
