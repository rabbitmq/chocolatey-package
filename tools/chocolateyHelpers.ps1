function Get-ChocolateyPackageParameters {
  $match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
  $arguments = @{}
  $packageParameters = ${Env:ChocolateyPackageParameters}

  if ($packageParameters) {
    if ($packageParameters -Match $match_pattern) {
      $results = $packageParameters | Select-String $match_pattern -AllMatches
      $results.matches | % {
        $arguments.Add(
        $_.Groups['option'].Value.Trim(),
        $_.Groups['value'].Value.Trim())
      }
    } else {
      throw "Package Parameters were found but were invalid (REGEX Failure)"
    }
  }

  return $arguments
}

function Get-RabbitMQPath {
  $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ"
  if (Test-Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ") {
    $regPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ"
  }

  if (Test-Path $regPath) {
    $path = (Get-ItemProperty -Name Install_Dir -Path 'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\RabbitMQ Server').Install_Dir
    $version = (Get-ItemProperty $regPath "DisplayVersion").DisplayVersion
    return Join-Path -Path $path -ChildPath "rabbitmq_server-$version"
  }
}
