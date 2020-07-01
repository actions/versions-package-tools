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