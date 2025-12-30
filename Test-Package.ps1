#Requires -Version 7.0
#Requires -Modules PSScriptAnalyzer

<#
.SYNOPSIS
Validates PowerShell scripts in the Chocolatey package.

.DESCRIPTION
Runs PSScriptAnalyzer on all PowerShell scripts to ensure they follow
best practices and don't have common issues.
#>

$packageRoot = Split-Path -Parent $PSCommandPath
$settingsPath = Join-Path -Path $packageRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
$filesToCheck = @(
    "$packageRoot\build-package.ps1"
    "$packageRoot\tools\chocolateyInstall.ps1.in"
    "$packageRoot\tools\chocolateyUninstall.ps1"
    "$packageRoot\tools\chocolateyHelpers.ps1"
)

$allPassed = $true

foreach ($file in $filesToCheck)
{
    if (Test-Path -LiteralPath $file)
    {
        Write-Information "Analyzing $file ..." -InformationAction Continue
        $results = Invoke-ScriptAnalyzer -Path $file -Settings $settingsPath -ExcludeRule @(
            'PSReviewUnusedParameter'  # False positive for parameters used in scriptblocks
        )
        if ($results)
        {
            $allPassed = $false
            $results | Format-Table -AutoSize
        }
    }
}

if ($allPassed)
{
    Write-Information "All checks passed!" -InformationAction Continue
    exit 0
}
else
{
    Write-Error "Some checks failed. See output above."
    exit 1
}
