#choco install rabbitmq -s '%cd%' -f --params="/RABBITMQ_BASE=C:\ProgramData\RabbitMQ"

##lifted from http://powershell.com/cs/blogs/tips/archive/2014/02/07/setting-and-deleting-environment-variables.aspx
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#$target = Join-Path $scriptPath "SetupRabbitMqManagement.bat"
. Join-Path $scriptPath "functions.ps1"


##This whole arguments section lifted shamelessly from the git.install package. Thanks guys!
$arguments = @{};
# /RabbitMQBase /GitAndUnixToolsOnPath /NoAutoCrlf
$packageParameters = $env:chocolateyPackageParameters;

# Now parse the packageParameters using good old regular expression
if ($packageParameters) {
	$match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
	$option_name = 'option'
	$value_name = 'value'

	if ($packageParameters -match $match_pattern ){
	$results = $packageParameters | Select-String $match_pattern -AllMatches
		$results.matches | % {
			$arguments.Add(
			$_.Groups[$option_name].Value.Trim(),
			$_.Groups[$value_name].Value.Trim())
		}
	}
	else
	{
		throw "Package Parameters were found but were invalid (REGEX Failure)"
	}
}







Install-ChocolateyPackage 'rabbitmq' 'EXE' '/S' 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.1/rabbitmq-server-3.5.1.exe' -validExitCodes @(0)


if ($arguments['RABBITMQ_BASE'])
{
    Set-EnvironmentVariable -Name RABBITMQ_BASE -Value $arguments['RABBITMQ_BASE'] -Target Machine
    $ENV:RABBITMQ_BASE = $arguments['RABBITMQ_BASE']
}
$rabbitPath = Get-RabbitMQPath
Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "stop"
Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "enable rabbitmq_management --offline"
Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "install"
Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "start"


#Start-ChocolateyProcessAsAdmin $target
				    
echo ""
echo "RabbitMQ Management Plugin enabled by default at http://localhost:15672"
echo ""

