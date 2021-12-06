<#
.SYNOPSIS
Check and return list of new available tool versions that not added to toolsets yet

.PARAMETER ToolName
Required parameter. The name of tool for which parser is available (Python, Xamarin, PyPy, Node, Go)
#>

param (
    [Parameter(Mandatory)]
    [ValidateSet("Python", "Xamarin", "PyPy", "Node", "Go")]
    [string] $ToolName,
    [string] $ReleasesUrl,
    [string] $FilterParameter,
    [string] $FilterArch
)

Get-ChildItem "$PSScriptRoot/parsers/verify-added-to-image/" | ForEach-Object {Import-Module $_.FullName}

if ($ToolName -in "Python", "PyPy", "Node", "Go") {
    $versionsToAdd = Search-ToolsVersionsNotOnImage -ToolName $ToolName -ReleasesUrl $ReleasesUrl -FilterParameter $FilterParameter -FilterArch $FilterArch
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
