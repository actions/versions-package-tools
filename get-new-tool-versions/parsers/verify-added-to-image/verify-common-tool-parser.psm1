function Search-ToolsVersionsNotOnImage {
    param (
        [string]$ToolName,
        [string]$ReleasesUrl,
        [string]$FilterParameter,
        [string]$FilterArch
    )
    
    $stableReleases = (Invoke-RestMethod $ReleasesUrl) | Where-Object stable -eq $true
    if ($ToolName -eq "Node") {
        $stableReleaseVersions = $stableReleases | ForEach-Object {$_.$FilterParameter.split(".")[0] + ".0"} |
            Select-Object -Unique
    } else {
        $stableReleaseVersions = $stableReleases | ForEach-Object {$_.$FilterParameter.split(".")[0,1] -join"."} |
            Select-Object -Unique
    }
    $toolsetUrl = "https://raw.githubusercontent.com/actions/virtual-environments/main/images/win/toolsets/toolset-2022.json"
    $latestMinorVersion = (Invoke-RestMethod $toolsetUrl).toolcache |
        Where-Object {$_.name -eq $ToolName -and $_.arch -eq $FilterArch} | 
        ForEach-Object {$_.versions.Replace("*","0")} |
        Select-Object -Last 1
    $versionsToAdd = $stableReleaseVersions | Where-Object {[version]$_ -gt [version]$latestMinorVersion}
    
    return $versionsToAdd
}