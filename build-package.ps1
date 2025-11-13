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
Write-Host "[INFO] curdir: $curdir"

New-Variable -Name latest_rabbitmq_tag -Option Constant `
  -Value $(& gh.exe release view --json tagName --repo rabbitmq/rabbitmq-server --jq .tagName)

Write-Host "[INFO] latest RabbitMQ tag:" $latest_rabbitmq_tag

New-Variable -Name rabbitmq_version -Option Constant -Value ($latest_rabbitmq_tag -replace 'v','')
New-Variable -Name rabbitmq_version_sortable -Option Constant -Value ($rabbitmq_version -replace '\.','')

Write-Host "[INFO] RabbitMQ version: $rabbitmq_version ($rabbitmq_version_sortable)"

# Get latest published RabbitMQ version
New-Variable -Name rabbitmq_choco_info -Option Constant `
    -Value (& choco search rabbitmq --limit-output | ConvertFrom-CSV -Delimiter '|' -Header 'Name','Version' | Where-Object { $_.Name -eq 'rabbitmq' })
New-Variable -Name rabbitmq_choco_version -Option Constant -Value $rabbitmq_choco_info.Version
New-Variable -Name rabbitmq_choco_version_sortable -Option Constant -Value ($rabbitmq_choco_version -replace '\.','')

Write-Host "[INFO] chocolatey.org RabbitMQ version: $rabbitmq_choco_version ($rabbitmq_choco_version_sortable)"

if (-Not($rabbitmq_version_sortable -gt $rabbitmq_choco_version_sortable))
{
    Write-Host "[INFO] newest RabbitMQ version already available on chocolatey.org"
    if (-Not($Force))
    {
        Write-Host "[INFO] exiting!"
        exit 0
    }
}

& gh.exe release download --repo rabbitmq/rabbitmq-server $latest_rabbitmq_tag --pattern '*.exe' --clobber

New-Variable -Name rabbitmq_installer_exe -Option Constant `
    -Value (Get-ChildItem -Filter 'rabbitmq-server-*.exe' | Sort-Object -Property Name -Descending | Select-Object -First 1)

Write-Host "[INFO] RabbitMQ installer exe: $rabbitmq_installer_exe"

New-Variable -Name rabbitmq_installer_exe_sha256 -Option Constant `
    -Value (Get-FileHash -LiteralPath $rabbitmq_installer_exe -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Host "[INFO] RabbitMQ installer sha256: $rabbitmq_installer_exe_sha256"

(Get-Content -Raw -LiteralPath rabbitmq.nuspec.in).Replace('@@RABBITMQ_VERSION@@', $rabbitmq_version) | Set-Content -LiteralPath rabbitmq.nuspec

New-Variable -Name chocolateyInstallPs1In -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1.in')

New-Variable -Name chocolateyInstallPs1 -Option Constant `
    -Value (Join-Path -Path $curdir -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1')

(Get-Content -Raw -LiteralPath $chocolateyInstallPs1In).Replace('@@RABBITMQ_VERSION@@', $rabbitmq_version).Replace('@@RABBITMQ_EXE_SHA256@@', $rabbitmq_installer_exe_sha256) | Set-Content -LiteralPath $chocolateyInstallPs1

& choco pack --limit-output
if ($LASTEXITCODE -eq 0)
{
    Write-Host "[INFO] 'choco pack' succeeded."
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
        Write-Host "[INFO] 'choco install rabbitmq' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco install rabbitmq' failed!"
    }

    & choco apikey --yes --key $ApiKey --source https://push.chocolatey.org/
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] 'choco apikey' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco apikey' failed!"
    }

    & choco push rabbitmq.$rabbitmq_version.nupkg --source https://push.chocolatey.org
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "[INFO] 'choco push' succeeded."
    }
    else
    {
        throw "[ERROR] 'choco push' failed!"
    }
}
