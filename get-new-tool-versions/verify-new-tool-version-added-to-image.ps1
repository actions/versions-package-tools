<#
.SYNOPSIS
Check and return list of new available tool versions that not added to toolsets yet

.PARAMETER ToolName
Required parameter. The name of tool for which parser is available (Python, Xamarin, PyPy)
#>

param (
    [Parameter(Mandatory)]
    [ValidateSet("Python", "Xamarin", "PyPy")]
    [string]$ToolName
)

Get-ChildItem "$PSScriptRoot/parsers/verify-added-to-image/" | ForEach-Object {Import-Module $_.FullName}

if ($ToolName -eq "Python") {
    $pythonVesionsManifestUrl = "https://raw.githubusercontent.com/actions/python-versions/main/versions-manifest.json"
    $versionsToAdd = Search-PythonVersionsNotOnImage -ToolName $ToolName -ReleasesUrl $pythonVesionsManifestUrl -FilterParameter "version" -FilterArch "x64"
}

if ($ToolName -eq "PyPy") {
    $pypyReleases = "https://downloads.python.org/pypy/versions.json"
    $versionsToAdd = Search-PythonVersionsNotOnImage -ToolName $ToolName -ReleasesUrl $pypyReleases -FilterParameter "python_version" -FilterArch "x86"
}

if ($ToolName -eq "Xamarin") {
    $xamarinReleases = "http://aka.ms/manifest/stable"
    $xamarinProducts = @(
        [PSCustomObject] @{name = 'Mono Framework'; property = 'mono-versions'}
        [PSCustomObject] @{name = 'Xamarin.Android'; property = 'android-versions'}
        [PSCustomObject] @{name = 'Xamarin.iOS'; property = 'ios-versions'}
        [PSCustomObject] @{name = 'Xamarin.Mac'; property = 'mac-versions'}
    )
    $versionsToAdd = Search-XamarinVersionsNotOnImage -ReleasesUrl $xamarinReleases -FilterProducts $xamarinProducts
    $joinChars = "\n\t"
}

$versionsToAdd = $versionsToAdd -join $joinChars

return $versionsToAdd
