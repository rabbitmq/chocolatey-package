. (Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'Shared.ps1')
Import-AUModule

$InformationPreference = 'Continue'

function global:au_BeforeUpdate
{
    $zipName = Split-Path -Leaf $Latest.URL64
    $ignoreFile = $zipName -replace '\.zip$', '.exe.ignore'
    $oldIgnore = Get-ChildItem -Path "$PSScriptRoot\tools" -Filter '*.exe.ignore' | Select-Object -First 1
    if ($oldIgnore -and $oldIgnore.Name -ne $ignoreFile)
    {
        Rename-Item -Path $oldIgnore.FullName -NewName $ignoreFile
    }
}

function global:au_SearchReplace
{
    @{
        ".\tools\chocolateyInstall.ps1" = @{
            "(^\s*\`$url\s*=\s*)('.*')" = "`$1'$($Latest.URL64)'"
            "(^\s*\`$checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
        }

        "rabbitmqadmin.nuspec" = @{
            "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`$2"
        }
    }
}

function global:au_GetLatest
{
    $releaseJson = & gh.exe release view --repo rabbitmq/rabbitmqadmin-ng --json 'tagName,url,assets'
    if ($LASTEXITCODE -ne 0)
    {
        throw "Failed to get release from GitHub"
    }

    $release = $releaseJson | ConvertFrom-Json
    $version = $release.tagName -replace '^v', ''

    $zipAsset = $release.assets | Where-Object { $_.name -match '^rabbitmqadmin-[0-9.]+-x86_64-pc-windows-msvc\.zip$' }
    if (-not $zipAsset)
    {
        throw "Could not find Windows zip in release assets"
    }

    return @{
        Version = $version
        URL64 = $zipAsset.url
        Checksum64 = ($zipAsset.digest -split ':')[1]
        ChecksumType64 = 'sha256'
        ReleaseNotes = $release.url
    }
}

Update-Package -ChecksumFor none
