@echo off
del *.nupkg
choco pack
choco install rabbitmq -fdvy -s "%cd%"