#Requires -Version 7.0

<#
.SYNOPSIS
Shared utility functions for AU package scripts

.DESCRIPTION
Common functions used across package update scripts.
#>

function Get-RepositoryRoot
{
    <#
    .SYNOPSIS
    Finds the repository root by searching for .git directory
    #>
    $current = $PSScriptRoot
    while ($current -and -not (Test-Path -PathType Container -LiteralPath (Join-Path $current '.git')))
    {
        $current = Split-Path -Path $current -Parent
    }
    if (-not $current)
    {
        throw "Could not find repository root (no .git directory found)"
    }
    return $current
}

function Import-AUModule
{
    <#
    .SYNOPSIS
    Imports the Chocolatey-AU module from submodule or global install
    #>
    if (-not (Get-Module -Name Chocolatey-AU -ListAvailable))
    {
        $repoRoot = Get-RepositoryRoot

        $auModulePath = Join-Path -Path $repoRoot -ChildPath '_modules'
        $auModulePath = Join-Path -Path $auModulePath -ChildPath 'au'
        $auModulePath = Join-Path -Path $auModulePath -ChildPath 'src'
        $auModulePath = Join-Path -Path $auModulePath -ChildPath 'Chocolatey-AU.psd1'
        if (-not (Test-Path $auModulePath))
        {
            throw "AU module not found at $auModulePath. Run 'git submodule update --init' first."
        }
        Import-Module -Force $auModulePath
    }
}
