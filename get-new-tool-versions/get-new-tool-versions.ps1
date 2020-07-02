<#
.SYNOPSIS
Check and return list of new available tool versions
#>

param (
    [Parameter(Mandatory)] [string] $DistURL,
    [Parameter(Mandatory)] [string] $ManifestLink,
    [string[]] $VersionFilterToInclude,
    [string[]] $VersionFilterToExclude,
    [UInt32] $RetryIntervalSec = 60,
    [UInt32] $RetryCount = 3
)

Import-Module (Join-Path $PSScriptRoot "helpers.psm1")

function Get-VersionsByUrl {
    param (
        [Parameter(Mandatory)] [string] $ToolPackagesUrl,
        [Parameter(Mandatory)] [UInt32] $RetryIntervalSec,
        [Parameter(Mandatory)] [UInt32] $RetryCount
    )

    $packages = Invoke-RestMethod $ToolPackagesUrl -MaximumRetryCount $RetryCount -RetryIntervalSec $RetryIntervalSec
    return $packages.version
}

if ($VersionFilterToInclude) {
    Validate-FiltersFormat -Filters $VersionFilterToInclude
}

if ($VersionFilterToExclude) {
    Validate-FiltersFormat -Filters $VersionFilterToExclude
}

Write-Host "Get the packages list from $DistURL"
$versionsFromDist = Get-VersionsByUrl -ToolPackagesUrl $DistURL `
                                      -RetryIntervalSec $RetryIntervalSec `
                                      -RetryCount $RetryCount

Write-Host "Get the packages list from $ManifestLink"
[Version[]] $versionsFromManifest = Get-VersionsByUrl -ToolPackagesUrl $ManifestLink `
                                                      -RetryIntervalSec $RetryIntervalSec `
                                                      -RetryCount $RetryCount

[Version[]] $formattedVersions = Format-Versions -Versions $versionsFromDist

$formattedVersions = Select-VersionsByFilter -Versions $formattedVersions `
                                             -IncludeFilters $VersionFilterToInclude `
                                             -ExcludeFilters $VersionFilterToExclude

$versionsToBuild = Skip-ExistingVersions -VersionsFromManifest $versionsFromManifest `
                                         -VersionsFromDist $formattedVersions

if ($versionsToBuild) {
    $availableVersions = $versionsToBuild -join ","
    Write-Host "The following versions are available to build:`n$availableVersions"
    Write-Output "##vso[task.setvariable variable=TOOL_VERSIONS]$availableVersions"
} else {
    Write-Host "There isn't versions to build"
}
