. (Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'Shared.ps1')
Import-AUModule

$InformationPreference = 'Continue'

function global:au_SearchReplace
{
    @{
        ".\tools\chocolateyInstall.ps1" = @{
            "(^\s*\`$version\s*=\s*)('.*')" = "`$1'$($Latest.Version)'"
            "(^\s*\`$checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
        }

        "rabbitmq.nuspec" = @{
            "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`$2"
        }
    }
}

function global:au_GetLatest
{
    $releaseJson = & gh.exe release view --repo rabbitmq/rabbitmq-server --json 'tagName,url,assets'
    if ($LASTEXITCODE -ne 0)
    {
        throw "Failed to get release from GitHub"
    }

    $release = $releaseJson | ConvertFrom-Json
    $version = $release.tagName -replace '^v', ''

    $exeAsset = $release.assets | Where-Object { $_.name -match '^rabbitmq-server-[0-9.]+\.exe$' }
    if (-not $exeAsset)
    {
        throw "Could not find Windows installer in release assets"
    }

    if ($exeAsset.digest)
    {
        $checksum = ($exeAsset.digest -split ':')[1]
    }
    else
    {
        $exeFile = Join-Path $PSScriptRoot "rabbitmq-server-$version.exe"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $exeAsset.url -OutFile $exeFile
        $ProgressPreference = 'Continue'
        $checksum = (Get-FileHash -Path $exeFile -Algorithm SHA256).Hash.ToLowerInvariant()
        Remove-Item $exeFile -Force
    }

    return @{
        Version = $version
        URL64 = $exeAsset.url
        Checksum64 = $checksum
        ChecksumType64 = 'sha256'
        ReleaseNotes = $release.url
    }
}

Update-Package -ChecksumFor none
