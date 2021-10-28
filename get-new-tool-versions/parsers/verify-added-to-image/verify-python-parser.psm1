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
    $toolsetUrl = "https://raw.githubusercontent.com/actions/virtual-environments/main/images/win/toolsets/toolset-2019.json"
    $latestExistingMinorVesion = ((Invoke-RestMethod $toolsetUrl).toolcache |
        Where-Object {$_.name -eq $ToolName -and $_.arch -eq $FilterArch}).versions |
        ForEach-Object {$_.split(".")[0,1] -join"."} |
        Select-Object -Last 1
    $versionsToAdd = $stableReleases | Where-Object {[version]$_ -gt [version]$latestExistingMinorVesion}
    
    return $versionsToAdd
}