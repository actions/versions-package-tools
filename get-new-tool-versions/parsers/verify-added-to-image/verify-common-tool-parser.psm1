function Search-PythonVersionsNotOnImage {
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
    $toolsetUrl = "https://raw.githubusercontent.com/shilovmaksim/virtual-environments/shilovmaksim/toolset-test/images/win/toolsets/toolset-2022.json"
    $latestVersion = ((Invoke-RestMethod $toolsetUrl).toolcache |
        Where-Object {$_.name -eq $ToolName -and $_.arch -eq $FilterArch}).versions |
        Select-Object -Last 1
    $latestMinorVesion = $latestVersion.Replace("*","0")
    $versionsToAdd = $stableReleaseVersions | Where-Object {[version]$_ -gt [version]$latestMinorVesion}
    
    return $versionsToAdd
}