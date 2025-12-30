#Requires -Version 7.0

<#
.SYNOPSIS
Builds and optionally publishes RabbitMQ Chocolatey package.

.DESCRIPTION
Checks for new RabbitMQ releases, downloads the installer, calculates checksums,
generates package files from templates, and optionally tests and publishes to
chocolatey.org.

.PARAMETER Force
Build the package even if the version is already published on chocolatey.org.

.PARAMETER Push
Test the package installation locally and push to chocolatey.org.

.PARAMETER ApiKey
Chocolatey API key for publishing. Required when using -Push.

.EXAMPLE
.\build-package.ps1
Checks for new version and builds package if newer than chocolatey.org

.EXAMPLE
.\build-package.ps1 -Force
Builds package regardless of published version

.EXAMPLE
.\build-package.ps1 -Push -ApiKey "your-api-key"
Builds, tests, and publishes package to chocolatey.org
#>

param(
    [switch]$Force = $false,
    [switch]$Push = $false,
    [string]$ApiKey = $null
)

$InformationPreference = 'Continue'
$DebugPreference = "Continue"
$ErrorActionPreference = 'Stop'
# Set-PSDebug -Strict -Trace 1
Set-PSDebug -Off
Set-StrictMode -Version 'Latest' -ErrorAction 'Stop' -Verbose

function Join-PathMultiple
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Base,
        [Parameter(Mandatory = $true)]
        [string[]]$Parts
    )
    $result = $Base
    foreach ($part in $Parts)
    {
        $result = Join-Path -Path $result -ChildPath $part
    }
    return $result
}

function Invoke-CommandWithCheck
{
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )
    & $Command
    if ($LASTEXITCODE -eq 0)
    {
        Write-Information "[INFO] '$Description' succeeded."
    }
    else
    {
        throw "[ERROR] '$Description' failed!"
    }
}

New-Variable -Name curdir  -Option Constant -Value $PSScriptRoot
Write-Information "[INFO] curdir: $curdir"

New-Variable -Name latest_rabbitmq_tag -Option Constant `
    -Value $(& gh.exe release view --json tagName --repo rabbitmq/rabbitmq-server --jq .tagName)

Write-Information "[INFO] latest RabbitMQ tag: $latest_rabbitmq_tag"

New-Variable -Name rabbitmq_version -Option Constant -Value ([version]($latest_rabbitmq_tag -replace 'v', ''))

Write-Information "[INFO] RabbitMQ version: $rabbitmq_version"

# Get latest published RabbitMQ version
New-Variable -Name rabbitmq_choco_info -Option Constant `
    -Value (choco.exe search rabbitmq --limit-output | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version' | Where-Object { $_.Name -eq 'rabbitmq' })

New-Variable -Name rabbitmq_choco_version -Option Constant -Value ([version]$rabbitmq_choco_info.Version)

Write-Information "[INFO] chocolatey.org RabbitMQ version: $rabbitmq_choco_version"

if ($rabbitmq_version -le $rabbitmq_choco_version)
{
    Write-Information "[INFO] newest RabbitMQ version already available on chocolatey.org"
    if (-not($Force))
    {
        Write-Information "[INFO] exiting!"
        exit 0
    }
}

Invoke-CommandWithCheck -Command { gh.exe release download --repo 'rabbitmq/rabbitmq-server' $latest_rabbitmq_tag --pattern '*.exe' --clobber } -Description 'gh release download'

New-Variable -Name rabbitmq_installer_exe -Option Constant `
    -Value (Get-ChildItem -Filter 'rabbitmq-server-*.exe' | Sort-Object -Property Name -Descending | Select-Object -First 1)

Write-Information "[INFO] RabbitMQ installer exe: $rabbitmq_installer_exe"

New-Variable -Name rabbitmq_installer_exe_sha256 -Option Constant `
    -Value (Get-FileHash -LiteralPath $rabbitmq_installer_exe -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Information "[INFO] RabbitMQ installer sha256: $rabbitmq_installer_exe_sha256"

(Get-Content -Raw -LiteralPath rabbitmq.nuspec.in).Replace('@@RABBITMQ_VERSION@@', $rabbitmq_version) | Set-Content -LiteralPath rabbitmq.nuspec

New-Variable -Name chocolateyInstallPs1In -Option Constant `
    -Value (Join-PathMultiple -Base $curdir -Parts @('tools', 'chocolateyInstall.ps1.in'))

New-Variable -Name chocolateyInstallPs1 -Option Constant `
    -Value (Join-PathMultiple -Base $curdir -Parts @('tools', 'chocolateyInstall.ps1'))

(Get-Content -Raw -LiteralPath $chocolateyInstallPs1In).Replace('@@RABBITMQ_VERSION@@', $rabbitmq_version).Replace('@@RABBITMQ_EXE_SHA256@@', $rabbitmq_installer_exe_sha256) | Set-Content -LiteralPath $chocolateyInstallPs1

Invoke-CommandWithCheck -Command { choco.exe pack --limit-output } -Description 'choco pack'

if ($Push)
{
    Invoke-CommandWithCheck -Command { choco.exe install rabbitmq -dv -source ".;https://chocolatey.org/api/v2/" } -Description 'choco install rabbitmq'

    Invoke-CommandWithCheck -Command { choco.exe apikey --yes --key $ApiKey --source https://push.chocolatey.org/ } -Description 'choco apikey'

    Invoke-CommandWithCheck -Command { choco.exe push rabbitmq.$rabbitmq_version.nupkg --source https://push.chocolatey.org } -Description 'choco push'
}
