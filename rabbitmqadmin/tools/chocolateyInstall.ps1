$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.30.0/rabbitmqadmin-2.30.0-x86_64-pc-windows-msvc.zip'
$checksum = '878d9b6e5bc8cd744a0e1a1d95d46fb6fe0aa0910389b13884f2e961fcb22ccb'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
