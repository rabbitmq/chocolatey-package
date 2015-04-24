
try {

	Install-ChocolateyPackage 'rabbitmq' 'EXE' '/S' 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.1/rabbitmq-server-3.5.1.exe' -validExitCodes @(0)

	$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
	$target = Join-Path $scriptPath "SetupRabbitMqManagement.bat"

	Start-ChocolateyProcessAsAdmin $target
				    
  echo ""
  echo "RabbitMQ Management Plugin enabled by default at http://localhost:15672"
  echo ""

  Write-ChocolateySuccess 'RabbitMQ'
} catch {
  Write-ChocolateyFailure 'RabbitMQ' $($_.Exception.Message)
  throw 
}
