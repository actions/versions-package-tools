<#
.SYNOPSIS
Check and return list of new available tool versions

.PARAMETER ToolName
Required parameter. The name of tool for which parser is available (Node, Go, Python, Xamarin)
#>

param (
    [Parameter(Mandatory)] [string] $ToolName
)

if ($ToolName -eq "Python") {
    $builtStableMinorVersionsList = ((Invoke-RestMethod "https://raw.githubusercontent.com/actions/python-versions/main/versions-manifest.json") | Where-Object {$_.stable -eq "True"} | Select-Object -First 10).version | ForEach-Object {$_.split(".")[0,1] -join(".")} | Select-Object -Unique
    $existingMinorVesionsList = ((Invoke-RestMethod "https://raw.githubusercontent.com/actions/virtual-environments/main/images/win/toolsets/toolset-2019.json").toolcache | Where-Object {$_.name -eq "Python" -and $_.arch -eq "x64"}).versions | ForEach-Object {$_.split(".")[0,1] -join(".")} | Select-Object -Unique
    $versionsToAdd = $builtStableMinorVersionsList | Where-Object {$_ -notin $existingMinorVesionsList}
}

if ($ToolName -eq "Xamarin") {
    $xamarinReleases = (Invoke-RestMethod "http://aka.ms/manifest/stable").items
    $xamarinProducts = @('Mono Framework', 'Xamarin.Android', 'Xamarin.iOS', 'Xamarin.Mac')
    $filteredReleases = $xamarinReleases | Where-Object {$_.name -in $xamarinProducts} | Sort-Object name | Select-Object name, version
    $uploadedReleases = (Invoke-RestMethod "https://raw.githubusercontent.com/actions/virtual-environments/main/images/macos/toolsets/toolset-11.json").xamarin
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
