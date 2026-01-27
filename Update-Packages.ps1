# AU Packages Template: https://github.com/chocolatey-community/chocolatey-packages-template

param([string[]] $Name, [string] $ForcedPackages, [string] $Root = $PSScriptRoot)

. (Join-Path -Path $PSScriptRoot -ChildPath 'Shared.ps1')
Import-AUModule

$InformationPreference = 'Continue'

if (Test-Path $PSScriptRoot/update_vars.ps1) { . $PSScriptRoot/update_vars.ps1 }

$Options = [ordered]@{
    WhatIf        = $au_WhatIf
    Force         = $false
    Timeout       = 100
    UpdateTimeout = 1200
    Threads       = 10
    Push          = $Env:au_Push -eq 'true'
    PushAll       = $true

    IgnoreOn = @(
        'Could not create SSL/TLS secure channel'
        'Could not establish trust relationship'
        'The operation has timed out'
        'Internal Server Error'
        'Service Temporarily Unavailable'
    )

    RepeatOn = @(
        'Could not create SSL/TLS secure channel'
        'Could not establish trust relationship'
        'Unable to connect'
        'The remote name could not be resolved'
        'Choco pack failed with exit code 1'
        'The operation has timed out'
        'Internal Server Error'
        'An exception occurred during a WebClient request'
        'remote session failed with an unexpected state'
    )

    Report = @{
        Type   = 'markdown'
        Path   = "$PSScriptRoot\Update-AUPackages.md"
        Params = @{
            Github_UserRepo = $Env:github_user_repo
            NoAppVeyor      = $true
            NoIcons         = $false
            IconSize        = 32
        }
    }

    History = @{
        Lines           = 120
        Github_UserRepo = $Env:github_user_repo
        Path            = "$PSScriptRoot\Update-History.md"
    }

    Gist = @{
        Id     = $Env:gist_id
        ApiKey = $Env:github_api_key
        Path   = "$PSScriptRoot\Update-AUPackages.md", "$PSScriptRoot\Update-History.md"
    }

    Git = @{
        User     = ''
        Password = $Env:github_api_key
        Branch   = 'main'
    }

    RunInfo = @{
        Exclude = 'password', 'apikey', 'apitoken'
        Path    = "$PSScriptRoot\update_info.xml"
    }

    ForcedPackages = $ForcedPackages -split ' '
    BeforeEach     = {
        param($PackageName, $Options)

        $pattern = "^${PackageName}(?:\\(?<stream>[^:]+))?(?:\:(?<version>.+))?$"
        $p = $Options.ForcedPackages | Where-Object { $_ -match $pattern }
        if (!$p) { return }

        $global:au_Force = $true
        $global:au_IncludeStream = $Matches['stream']
        $global:au_Version = $Matches['version']
    }
}

if ($ForcedPackages) { Write-Information "FORCED PACKAGES: $ForcedPackages" }
$global:au_Root = $Root
$global:info = Update-AUPackages -Name $Name -Options $Options
