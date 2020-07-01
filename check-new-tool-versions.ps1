<#
.SYNOPSIS
Check and return list of new available tool versions
#>

param (
    [Parameter(Mandatory)] [string] $DistURL,
    [Parameter(Mandatory)] [string] $ManifestLink,
    [string] $VersionFilterToInclude,
    [string] $VersionFilterToExclude,
    [UInt32] $RetryIntervalSec = 60,
    [UInt32] $RetryCount = 3
)

function Get-VersionsByUrl {
    param (
        [Parameter(Mandatory)] [string] $ToolPackagesUrl,
        [Parameter(Mandatory)] [UInt32] $RetryIntervalSec,
        [Parameter(Mandatory)] [UInt32] $RetryCount
    )

    $packages = Invoke-RestMethod $ToolPackagesUrl -MaximumRetryCount $RetryCount -RetryIntervalSec $RetryIntervalSec
    return $packages.version
}

function Format-Versions {
    param (
        [Parameter(Mandatory)] [string[]] $Versions
    )

    [Version[]] $formattedVersions = @()
    
    foreach($version in $Versions) { 
        $substredVersion = $null
        
        # We cut a string from index of first digit because initially it has invalid format (v14.4.0 or go1.14.4)
        if ($version -match '(?<number>\d)') {
            $firstDigitIndex = $version.indexof($Matches.number)
            $substredVersion = $version.substring($firstDigitIndex)
        } else {
            Write-Host "Invalid version format - $version"
            exit 1
        }
        
        # We filter versions to exclude unstable (for example: "go1.15beta1")
        # Valid version format: x.x or x.x.x
        if ($substredVersion -notmatch '^\d+\.+\d+\.*\d*$') {
            continue
        }

        if ($substredVersion.Split(".").Length -lt 3) {
            $formattedVersions += "$substredVersion.0"
        } else {
            $formattedVersions += $substredVersion
        }  
    }

    return $formattedVersions
}

function Filter-Versions {
    param (
        [Parameter(Mandatory)] [string[]] $Versions,
        [Parameter(Mandatory)] [string] $VersionFilter,
        [Parameter(Mandatory)] [bool] $IncludeVersions
    )

    $versionFilters = $VersionFilter.Split(',')
    [Version[]] $filteredVersions = @()

    foreach($filter in $versionFilters) {
        if ($IncludeVersions) {
            $filteredVersions += $Versions | Where-Object { $_ -like $filter }
        } else {
            $filteredVersions += $Versions | Where-Object { $_ -notlike $filter }
        }
    }

    return $filteredVersions
}

function Get-VersionsToBuild {
    param (
        [Parameter(Mandatory)] [string[]] $VersionsFromManifest,
        [Parameter(Mandatory)] [string[]] $VersionsFromDist
    )

    [System.Collections.ArrayList]$versionsToBuid = $VersionsFromDist
    $VersionsFromManifest | ForEach-Object { $versionsToBuid.Remove($_) }

    return $versionsToBuid
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

if (-not ([string]::IsNullOrEmpty($VersionFilterToInclude))) {
    $formattedVersions = Filter-Versions -Versions $formattedVersions `
                                         -VersionFilter $VersionFilterToInclude `
                                         -IncludeVersions $true
}

if (-not ([string]::IsNullOrEmpty($VersionFilterToExclude))) {
    $formattedVersions = Filter-Versions -Versions $formattedVersions `
                                         -VersionFilter $VersionFilterToExclude `
                                         -IncludeVersions $false
}

$versionsToBuild = Get-VersionsToBuild -VersionsFromManifest $versionsFromManifest `
                                       -VersionsFromDist $formattedVersions

if ([string]::IsNullOrEmpty($versionsToBuild)) {
    Write-Host "There isn't versions to build"
    return $null
} else {
    Write-Host "The following versions are available to build:`n$versionsToBuild"
    return "$versionsToBuild"
}
