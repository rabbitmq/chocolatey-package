$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.28.0/rabbitmqadmin-2.28.0-x86_64-pc-windows-msvc.zip'
$checksum = '7428e7dda2135d7f9922b172cdd59e00b79bdd8951c56e2f46ce3fc5eecc5fa1'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
