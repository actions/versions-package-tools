function Format-Versions {
    param (
        [Parameter(Mandatory)] [string[]] $Versions
    )

    [Version[]] $formattedVersions = @()
    
    foreach($version in $Versions) { 
        $substredVersion = $null
        
        # Cut a string from index of first digit because initially it has invalid format (v14.4.0 or go1.14.4)
        if (-not ($version -match '(?<number>\d)')) {
            Write-Host "Invalid version format - $version"
            exit 1  
        }
        $firstDigitIndex = $version.indexof($Matches.number)
        $substredVersion = $version.substring($firstDigitIndex)
        
        # Filter versions to exclude unstable (for example: "go1.15beta1")
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

function Skip-ExistingVersions {
    param (
        [Parameter(Mandatory)] [string[]] $VersionsFromManifest,
        [Parameter(Mandatory)] [string[]] $VersionsFromDist
    )

    $newVersions = @()
    $newVersions += $VersionsFromDist | Where-Object { $VersionsFromManifest -notcontains $_ }

    return $newVersions
}