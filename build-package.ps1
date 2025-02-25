param(
    [switch]$Push = $false,
    [string]$ApiKey = $env:CHOCOLATEY_API_KEY
)

if ($Push)
{
    $PackAndTest = $true
    Write-Host "[INFO] PACKAGE WILL BE TESTED AND PUSHED"
}

$DebugPreference = "Continue"
$ErrorActionPreference = 'Stop'
# Set-PSDebug -Strict -Trace 1
Set-PSDebug -Off
Set-StrictMode -Version 'Latest' -ErrorAction 'Stop' -Verbose

New-Variable -Name curdir  -Option Constant -Value $PSScriptRoot
Write-Host "[INFO] curdir: $curdir"

try
{
  $ProgressPreference = 'SilentlyContinue'
  New-Variable -Name rabbitmq_tags -Option Constant `
    -Value (Invoke-WebRequest -Uri 'https://api.github.com/repos/rabbitmq/rabbitmq-server/tags?per_page=100' | ConvertFrom-Json)
}
finally
{
  $ProgressPreference = 'Continue'
}

New-Variable -Name latest_rabbitmq_tag -Option Constant `
  -Value ($rabbitmq_tags | Where-Object { $_.name -match '^v4\.[0-9](\.[0-9](\.[0-9])?)?$' } | Sort-Object -Descending { $_.name } | Select-Object -First 1)

Write-Host "[INFO] latest RabbitMQ tag:" $latest_rabbitmq_tag.name

New-Variable -Name rabbitmq_version -Option Constant -Value ($latest_rabbitmq_tag.name -replace 'v','')
New-Variable -Name rabbitmq_version_sortable -Option Constant -Value ($rabbitmq_version -replace '\.','')

Write-Host "[INFO] RabbitMQ version: $rabbitmq_version ($rabbitmq_version_sortable)"

# Get latest published RabbitMQ version
New-Variable -Name rabbitmq_choco_info -Option Constant `
    -Value (& choco search rabbitmq --exact --limit-output | ConvertFrom-CSV -Delimiter '|' -Header 'Name','Version')
New-Variable -Name rabbitmq_choco_version -Option Constant -Value $rabbitmq_choco_info.version
New-Variable -Name rabbitmq_choco_version_sortable -Option Constant -Value ($rabbitmq_choco_version -replace '\.','')

Write-Host "[INFO] chocolatey.org RabbitMQ version: $rabbitmq_choco_version ($rabbitmq_choco_version_sortable)"

if (-Not($rabbitmq_version_sortable -gt $rabbitmq_choco_version_sortable))
{
    Write-Host "[INFO] newest RabbitMQ version already available on chocolatey.org, exiting!"
    exit 0
}

New-Variable -Name rabbitmq_release_uri -Option Constant `
  -Value ("https://api.github.com/repos/rabbitmq/rabbitmq-server/releases/tags/" + $latest_rabbitmq_tag.name)

try
{
  $ProgressPreference = 'SilentlyContinue'
  New-Variable -Name rabbitmq_release_json -Option Constant `
    -Value (Invoke-WebRequest -Uri $rabbitmq_release_uri | ConvertFrom-Json)
}
finally
{
  $ProgressPreference = 'Continue'
}

New-Variable -Name rabbitmq_installer_asset  -Option Constant `
    -Value ($rabbitmq_release_json.assets | Where-Object { $_.name -match '^rabbitmq-server-[0-9.]+\.exe$' })

New-Variable -Name rabbitmq_installer_exe -Option Constant -Value $rabbitmq_installer_asset.name

New-Variable -Name rabbitmq_installer_uri -Option Constant -Value $rabbitmq_installer_asset.browser_download_url

if (!(Test-Path -Path $rabbitmq_installer_exe))
{
    Write-Host "[INFO] downloading from " $rabbitmq_installer_uri
    try
    {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $rabbitmq_installer_uri -OutFile $rabbitmq_installer_exe
    }
    finally
    {
        $ProgressPreference = 'Continue'
    }
}

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

Set-PSDebug -Off
