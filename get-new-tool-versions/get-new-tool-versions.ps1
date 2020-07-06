<#
.SYNOPSIS
Check and return list of new available tool versions

.PARAMETER DistURL
Required parameter. Link to the json file included all available tool versions
.PARAMETER ManifestLink
Required parameter. Link to the the version-manifest.json file
.PARAMETER VersionFilterToInclude
Optional parameter. List of filters to include particular versions
.PARAMETER VersionFilterToExclude
Optional parameter. List of filters to exclude particular versions
.PARAMETER RetryIntervalSec
Optional parameter. Retry interval in seconds
.PARAMETER RetryCount
Optional parameter. Retry count
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

if (-not $formattedVersions) {
    Write-Host "Couldn't find available versions with current filters"
    exit 1
}

$versionsToBuild = Skip-ExistingVersions -VersionsFromManifest $versionsFromManifest `
                                         -VersionsFromDist $formattedVersions

if ($versionsToBuild) {
    $availableVersions = $versionsToBuild -join ","
    $toolVersions = $availableVersions.Replace(",",", ")
    Write-Host "The following versions are available to build:`n$toolVersions"
    Write-Output "##vso[task.setvariable variable=TOOL_VERSIONS;isOutput=true]$toolVersions"
} else {
    Write-Host "There aren't versions to build"
}
