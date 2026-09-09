$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = 'https://github.com/rabbitmq/rabbitmqadmin-ng/releases/download/v2.35.0/rabbitmqadmin-2.35.0-x86_64-pc-windows-msvc.zip'
$checksum = '46a5a3b47efdadf3dce12d18e69f83fcb0daf167279a5a75a51f77b03437d3eb'

Install-ChocolateyZipPackage -PackageName 'rabbitmqadmin' -Url $url -UnzipLocation $toolsDir -ChecksumType 'sha256' -Checksum $checksum
