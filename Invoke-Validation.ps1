#Requires -Version 7.0
#Requires -Modules PSScriptAnalyzer

<#
.SYNOPSIS
Validates PowerShell scripts in the Chocolatey package repository.

.DESCRIPTION
Runs PSScriptAnalyzer on all PowerShell scripts to ensure they follow
best practices and maintain consistent formatting.

Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
#>

$InformationPreference = 'Continue'
$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
if (-not $repoRoot)
{
    throw "PSScriptRoot is not set. This script must be run directly, not dot-sourced."
}

$settingsPath = Join-Path -Path $repoRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
if (-not (Test-Path $settingsPath))
{
    throw "PSScriptAnalyzer settings not found at: $settingsPath"
}

# Find all PowerShell scripts
$filesToCheck = Get-ChildItem -Path $repoRoot -Recurse -Include *.ps1, *.psm1 | Where-Object {
    $_.FullName -notmatch '\\(node_modules|\.git|_modules)\\'
}

$allPassed = $true

foreach ($file in $filesToCheck)
{
    Write-Information "Analyzing $($file.FullName)..."
    $results = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $settingsPath -ExcludeRule @(
        'PSReviewUnusedParameter'                       # False positive for parameters used in scriptblocks
        'PSAvoidGlobalVars'                             # Required by AU framework
        'PSAvoidUsingWriteHost'                         # AU framework uses Write-Information
        'PSAvoidUsingCmdletAliases'                     # AU framework uses aliases
        'PSUseShouldProcessForStateChangingFunctions'   # Helper functions don't need ShouldProcess
        'PSUseDeclaredVarsMoreThanAssignments'          # Some variables used for side effects
        'PSUseCmdletCorrectly'                          # False positive for Pop-Location without parameters
    )
    if ($results)
    {
        $allPassed = $false
        $results | Format-Table -AutoSize
    }
}

if ($allPassed)
{
    Write-Information "All checks passed!"
    exit 0
}
else
{
    Write-Error "Some checks failed. See output above."
    exit 1
}
