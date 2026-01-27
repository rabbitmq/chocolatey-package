function Get-RabbitMQPath
{
    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ'
    if (Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ')
    {
        $regPath = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\RabbitMQ'
    }

    if (Test-Path $regPath)
    {
        $uninstallString = (Get-ItemProperty $regPath "UninstallString").UninstallString.Trim('"')
        $path = Split-Path -Parent $uninstallString
        $version = (Get-ItemProperty $regPath "DisplayVersion").DisplayVersion
        return "$path\rabbitmq_server-$version"
    }
}
