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
    $path = Split-Path -Parent (Get-ItemProperty $regPath "UninstallString").UninstallString
    $version = (Get-ItemProperty $regPath "DisplayVersion").DisplayVersion
    return "$path\rabbitmq_server-$version"
  }
}
