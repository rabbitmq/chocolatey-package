#Requires -Version 7.0

param(
    [switch]$Force = $false,
    [switch]$Push = $false,
    [string]$ApiKey = $null
)

$DebugPreference = "Continue"
$ErrorActionPreference = 'Stop'
# Set-PSDebug -Strict -Trace 1
Set-PSDebug -Off
Set-StrictMode -Version 'Latest' -ErrorAction 'Stop' -Verbose

New-Variable -Name curdir  -Option Constant -Value $PSScriptRoot
Write-Information "[INFO] curdir: $curdir" -InformationAction Continue

New-Variable -Name latest_rabbitmq_tag -Option Constant `
    -Value $(& gh.exe release view --json tagName --repo rabbitmq/rabbitmq-server --jq .tagName)

Write-Information "[INFO] latest RabbitMQ tag: $latest_rabbitmq_tag" -InformationAction Continue

New-Variable -Name rabbitmq_version -Option Constant -Value ([version]($latest_rabbitmq_tag -replace 'v', ''))

Write-Information "[INFO] RabbitMQ version: $rabbitmq_version" -InformationAction Continue

# Get latest published RabbitMQ version
New-Variable -Name rabbitmq_choco_info -Option Constant `
    -Value (& choco search rabbitmq --limit-output | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version' | Where-Object { $_.Name -eq 'rabbitmq' })

New-Variable -Name rabbitmq_choco_version -Option Constant -Value ([version]$rabbitmq_choco_info.Version)

Write-Information "[INFO] chocolatey.org RabbitMQ version: $rabbitmq_choco_version" -InformationAction Continue

if ($rabbitmq_version -le $rabbitmq_choco_version)
{
    Write-Information "[INFO] newest RabbitMQ version already available on chocolatey.org" -InformationAction Continue
    if (-not($Force))
    {
        Write-Information "[INFO] exiting!" -InformationAction Continue
        exit 0
    }
}

& gh.exe release download --repo 'rabbitmq/rabbitmq-server' $latest_rabbitmq_tag --pattern '*.exe' --clobber

New-Variable -Name rabbitmq_installer_exe -Option Constant `
    -Value (Get-ChildItem -Filter 'rabbitmq-server-*.exe' | Sort-Object -Property Name -Descending | Select-Object -First 1)

Write-Information "[INFO] RabbitMQ installer exe: $rabbitmq_installer_exe" -InformationAction Continue

New-Variable -Name rabbitmq_installer_exe_sha256 -Option Constant `
    -Value (Get-FileHash -LiteralPath $rabbitmq_installer_exe -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Information "[INFO] RabbitMQ installer sha256: $rabbitmq_installer_exe_sha256" -InformationAction Continue

(Get-Content -Raw -LiteralPath rabbitmq.nuspec.in).Replace('@@RABBITMQ_VERSION@@', $rabbitmq_version) | Set-Content -LiteralPath rabbitmq.nuspec

New-Variable -Name chocolateyInstallPs1In -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1.in')

New-Variable -Name chocolateyInstallPs1 -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1')

(Get-Content -Raw -LiteralPath $chocolateyInstallPs1In).Replace('@@RABBITMQ_VERSION@@', $rabbitmq_version).Replace('@@RABBITMQ_EXE_SHA256@@', $rabbitmq_installer_exe_sha256) | Set-Content -LiteralPath $chocolateyInstallPs1

& choco pack --limit-output
if ($LASTEXITCODE -eq 0)
{
    Write-Information "[INFO] 'choco pack' succeeded." -InformationAction Continue
}
else
{
    throw "[ERROR] 'choco pack' failed!"
}

if ($Push)
{
    & choco install rabbitmq -dv -source ".;https://chocolatey.org/api/v2/"
    if ($LASTEXITCODE -eq 0)
    {
        Write-Information "[INFO] 'choco install rabbitmq' succeeded." -InformationAction Continue
    }
    else
    {
        throw "[ERROR] 'choco install rabbitmq' failed!"
    }

    & choco apikey --yes --key $ApiKey --source https://push.chocolatey.org/
    if ($LASTEXITCODE -eq 0)
    {
        Write-Information "[INFO] 'choco apikey' succeeded." -InformationAction Continue
    }
    else
    {
        throw "[ERROR] 'choco apikey' failed!"
    }

    & choco push rabbitmq.$rabbitmq_version.nupkg --source https://push.chocolatey.org
    if ($LASTEXITCODE -eq 0)
    {
        Write-Information "[INFO] 'choco push' succeeded." -InformationAction Continue
    }
    else
    {
        throw "[ERROR] 'choco push' failed!"
    }
}
