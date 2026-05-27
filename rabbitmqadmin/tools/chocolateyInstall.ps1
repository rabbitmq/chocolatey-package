$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.31.0/rabbitmqadmin-2.31.0-x86_64-pc-windows-msvc.zip'
$checksum = '913b13de4b4c656f026bc7c107575196a4f56ea459dc9028e2c9594eef338bd2'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
