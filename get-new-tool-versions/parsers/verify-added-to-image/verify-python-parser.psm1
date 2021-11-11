function Search-PythonVersionsNotOnImage {
    param (
        [string]$ToolName,
        [string]$ReleasesUrl,
        [string]$FilterParameter,
        [string]$FilterArch
    )
    
    $stableReleases = (Invoke-RestMethod $ReleasesUrl) |
        Where-Object stable -eq $true |
        ForEach-Object {$_.$FilterParameter.split(".")[0,1] -join"."} |
        Select-Object -Unique
    $toolsetUrl = "https://raw.githubusercontent.com/actions/virtual-environments/main/images/win/toolsets/toolset-2022.json"
    $latestVersion = ((Invoke-RestMethod $toolsetUrl).toolcache |
        Where-Object {$_.name -eq $ToolName -and $_.arch -eq $FilterArch}).versions |
        Select-Object -Last 1
    $latestMinorVesion = $latestVersion.TrimEnd(".*")
    $versionsToAdd = $stableReleases | Where-Object {[version]$_ -gt [version]$latestMinorVesion}
    
    return $versionsToAdd
}