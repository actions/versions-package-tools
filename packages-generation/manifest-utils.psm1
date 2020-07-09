function Read-ConfigurationFile {
    param ([Parameter(Mandatory)][string]$Filepath)
    return Get-Content $Filepath -Raw | ConvertFrom-Json
}

function New-AssetItem {
    param (
        [Parameter(Mandatory)][object]$ReleaseAsset,
        [Parameter(Mandatory)][object]$Configuration
    )
    $regexResult = [regex]::Match($ReleaseAsset.name, $Configuration.regex)
    if (-not $regexResult.Success) { throw "Can't match asset filename '$($_.name)' to regex" }

    $result = New-Object PSObject
    $result | Add-Member -Name "filename" -Value $ReleaseAsset.name -MemberType NoteProperty
    $Configuration.groups.PSObject.Properties | ForEach-Object {
        if (($_.Value).GetType().Name.StartsWith("Int")) {
            $value = $regexResult.Groups[$_.Value].Value
        } else {
            $value = $_.Value
        }

        if (-not ([string]::IsNullOrEmpty($value))) {
            $result | Add-Member -Name $_.Name -Value $value -MemberType NoteProperty
        }
    }

    $result | Add-Member -Name "download_url" -Value $ReleaseAsset.browser_download_url -MemberType NoteProperty
    return $result
}

function Get-VersionFromRelease {
    param (
        [Parameter(Mandatory)][object]$Release
    )
    # Release name can contain additional information after ':' so filter it
    [string]$releaseName = $Release.name.Split(':')[0]
    [Semver]$version = $null
    if (![Semver]::TryParse($releaseName, [ref]$version)) {
        throw "Release '$($Release.id)' has invalid title '$($Release.name)'. It can't be parsed as version. ( $($Release.html_url) )"
    }

    return $version
}

function Build-VersionsManifest {
    param (
        [Parameter(Mandatory)][array]$Releases,
        [Parameter(Mandatory)][object]$Configuration
    )

    $Releases = $Releases | Sort-Object -Property "published_at" -Descending

    $versionsHash = @{}
    foreach ($release in $Releases) {
        if (($release.draft -eq $true) -or ($release.prerelease -eq $true)) {
            continue
        }

        [Semver]$version = Get-VersionFromRelease $release
        $versionKey = $version.ToString()

        if ($versionsHash.ContainsKey($versionKey)) {
            continue
        }
        
        $stable = $version.PreReleaseLabel ? $false : $true
        $versionsHash.Add($versionKey, [PSCustomObject]@{
            version = $versionKey
            stable = $stable
            release_url = $release.html_url
            files = $release.assets | ForEach-Object { New-AssetItem -ReleaseAsset $_ -Configuration $Configuration }
        })
    }

    # Sort versions by descending
    return $versionsHash.Values | Sort-Object -Property @{ Expression = { [Semver]$_.version }; Descending = $true }
}