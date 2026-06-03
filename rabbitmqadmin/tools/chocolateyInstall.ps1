$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.32.0/rabbitmqadmin-2.32.0-x86_64-pc-windows-msvc.zip'
$checksum = 'e315089d1c9ed78b66d045c6032e5155a2cf1020751ad23604ab975fe6402d17'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
