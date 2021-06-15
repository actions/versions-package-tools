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
    $ltsRules = Get-LtsRules -Configuration $Configuration

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
        
        $ltsStatus = Get-VersionLtsStatus -Version $versionKey -LtsRules $ltsRules
        $stable = $version.PreReleaseLabel ? $false : $true
        [array]$releaseAssets = $release.assets | ForEach-Object { New-AssetItem -ReleaseAsset $_ -Configuration $Configuration }

        $versionHash = [PSCustomObject]@{}
        $versionHash | Add-Member -Name "version" -Value $versionKey -MemberType NoteProperty
        $versionHash | Add-Member -Name "stable" -Value $stable -MemberType NoteProperty
        if ($ltsStatus) { $versionHash | Add-Member -Name "lts" -Value $ltsStatus -MemberType NoteProperty }
        $versionHash | Add-Member -Name "release_url" -Value $release.html_url -MemberType NoteProperty
        $versionHash | Add-Member -Name "files" -Value $releaseAssets -MemberType NoteProperty
        $versionsHash.Add($versionKey, $versionHash)
    }

    # Sort versions by descending
    return $versionsHash.Values | Sort-Object -Property @{ Expression = { [Semver]$_.version }; Descending = $true }
}

function Get-LtsRules {
    param (
        [Parameter(Mandatory)][object]$Configuration
    )

    $ruleExpression = $Configuration."lts_rule_expression"
    if ($ruleExpression) {
        Invoke-Expression $ruleExpression
    } else {
        @()
    }
}

function Get-VersionLtsStatus {
    param (
        [Parameter(Mandatory)][string]$Version,
        [array]$LtsRules
    )

    foreach ($ltsRule in $LtsRules) {
        if (($Version -eq $ltsRule.Name) -or ($Version.StartsWith("$($ltsRule.Name)."))) {
            return $ltsRule.Value
        }
    }

    return $null

}

# Invoke-RestMethod "https://raw.githubusercontent.com/nodejs/Release/main/schedule.json"
# $arr.PSObject.Properties | Where-Object { $_.Value.codename } | ForEach-Object { @( @{ $_.Name = $_.Value.codename }) }
# (Invoke-RestMethod 'https://raw.githubusercontent.com/nodejs/Release/main/schedule.json').PSObject.Properties | Where-Object { $_.Value.codename } | ForEach-Object { @{ Name = $_.Name.TrimStart('v'); Value = $_.Value.codename } }