#choco install rabbitmq -s '%cd%' -f --params="/RABBITMQBASE:C:\ProgramData\RabbitMQ"


function Get-RabbitMQPath
{
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ"
    if (Test-Path "HKLM:\SOFTWARE\Wow6432Node\") { $regPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ" }
    if (!(Test-Path $regPath)) { return $false }
    $path = Split-Path -Parent (Get-ItemProperty $regPath "UninstallString").UninstallString
    $version = (Get-ItemProperty $regPath "DisplayVersion").DisplayVersion
    return "$path\rabbitmq_server-$version"
}

#Write-Output (Get-RabbitMQPath)
#exit

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





if ($arguments['RABBITMQBASE'])
{
    Write-Output "Setting RABBITMQ_BASE"
    [System.Environment]::SetEnvironmentVariable("RABBITMQ_BASE", $arguments['RABBITMQBASE'], "Machine" )
    $ENV:RABBITMQ_BASE = $arguments['RABBITMQBASE']
}

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Install-ChocolateyPackage 'rabbitmq' 'EXE' '/S' 'http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.4/rabbitmq-server-3.5.4.exe' -validExitCodes @(0)


$rabbitPath = Get-RabbitMQPath
Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "stop"

if (!($arguments['NOMANAGEMENT']))
{
    Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "enable rabbitmq_management --offline"
	Start-Process -wait "$rabbitPath\sbin\rabbitmq-plugins.bat" "enable rabbitmq_management"
}

Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "install"
Start-Process -wait "$rabbitPath\sbin\rabbitmq-service.bat" "start"


#Start-ChocolateyProcessAsAdmin $target
				    
echo ""
echo "RabbitMQ Management Plugin enabled by default at http://localhost:15672"
echo ""

