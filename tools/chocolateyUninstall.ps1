try {
  start-process -wait "C:\Program Files (x86)\RabbitMQ Server\uninstall"

  Write-ChocolateySuccess 'RabbitMQ'
} catch {

  Write-ChocolateySuccess 'RabbitMQ'
}
