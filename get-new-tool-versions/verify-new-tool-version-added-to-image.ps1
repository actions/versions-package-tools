<#
.SYNOPSIS
Check and return list of new available tool versions that not added to toolsets yet

.PARAMETER ToolName
Required parameter. The name of tool for which parser is available (Python, Xamarin)
#>

param (
    [Parameter(Mandatory)]
    [ValidateSet("Python", "Xamarin")]
    [string]$ToolName
)

if ($ToolName -eq "Python") {
    $pythonVesionsManifestUrl = "https://raw.githubusercontent.com/actions/python-versions/main/versions-manifest.json"
    $builtStableMinorVersions = (Invoke-RestMethod $pythonVesionsManifestUrl) |
        Where-Object stable -eq $true |
        ForEach-Object {$_.version.split(".")[0,1] -join"."} |
        Select-Object -Unique
    $toolsetUrl = "https://raw.githubusercontent.com/actions/virtual-environments/main/images/win/toolsets/toolset-2019.json"
    $latestExistingMinorVesion = ((Invoke-RestMethod $toolsetUrl).toolcache |
        Where-Object {$_.name -eq "Python" -and $_.arch -eq "x64"}).versions |
        ForEach-Object {$_.split(".")[0,1] -join"."} |
        Select-Object -Last 1
    $versionsToAdd = $builtStableMinorVersions | Where-Object {[version]$_ -gt [version]$latestExistingMinorVesion}
}

if ($ToolName -eq "Xamarin") {
    $xamarinReleases = (Invoke-RestMethod "http://aka.ms/manifest/stable").items
    $xamarinProducts = @('Mono Framework', 'Xamarin.Android', 'Xamarin.iOS', 'Xamarin.Mac')
    $filteredReleases = $xamarinReleases | Where-Object {$_.name -in $xamarinProducts} | Sort-Object name | Select-Object name, version
    $toolsetUrl = "https://raw.githubusercontent.com/actions/virtual-environments/main/images/macos/toolsets/toolset-11.json"
    $uploadedReleases = (Invoke-RestMethod $toolsetUrl).xamarin
    $releasesOnImage = @{
        'Mono Framework' = $uploadedReleases.'mono-versions'
        'Xamarin.Android' = $uploadedReleases.'android-versions'
        'Xamarin.iOS' = $uploadedReleases.'ios-versions'
        'Xamarin.Mac' = $uploadedReleases.'mac-versions'
    }
    $versionsToAdd = $filteredReleases | Where-Object {$releasesOnImage[$_.name] -notcontains $_.version } | ForEach-Object {[string]::Empty} {
        '{0,-15} : {1}' -f $_.name, $_.version
    }
    $joinChars = "\n\t"
}
$versionsToAdd = $versionsToAdd -join $joinChars

return $versionsToAdd
