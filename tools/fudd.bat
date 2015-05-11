@echo off
start /wait c:\progra~2\rabbit~1\uninstall.exe
pause
taskkill /f /im epmd.exe
pause
rmdir /s /q %appdata%\RabbitMQ
rmdir /s /q c:\programdata\rabbitmq