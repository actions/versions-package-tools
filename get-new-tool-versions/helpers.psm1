function Validate-FiltersFormat {
    param (
        [Parameter(Mandatory)] [string[]] $Filters
    )

    foreach($filter in $Filters) {
        $filter.Split('.') | ForEach-Object {
            if (($_ -notmatch '^\d+$') -and ($_ -ne '*')) {
                throw "Invalid filter format - $filter"
            }
        }
    }
}

function Format-Versions {
    param (
        [Parameter(Mandatory)] [string[]] $Versions
    )

    [Version[]] $formattedVersions = @()
    
    foreach($version in $Versions) {
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

function Select-VersionsByFilter {
    param (
        [Parameter(Mandatory)] [version[]] $Versions,
        [string[]] $IncludeFilters,
        [string[]] $ExcludeFilters
    )

    if ($IncludeFilters.Length -eq 0) {
        $IncludeFilters = @('*')
    }

    return $Versions | Where-Object {
        $ver = $_
        $matchedIncludeFilters = $IncludeFilters | Where-Object { $ver -like $_ }
        $matchedExcludeFilters = $ExcludeFilters | Where-Object { $ver -like $_ }
        $matchedIncludeFilters -and (-not $matchedExcludeFilters)
    }
}

function Skip-ExistingVersions {
    param (
        [Parameter(Mandatory)] [string[]] $VersionsFromManifest,
        [Parameter(Mandatory)] [string[]] $VersionsFromDist
    )

    return $VersionsFromDist | Where-Object { $VersionsFromManifest -notcontains $_ }
}