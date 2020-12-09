<#
.SYNOPSIS
Check and return list of new available tool versions

.PARAMETER DistURL
Required parameter. Link to the json file included all available tool versions
.PARAMETER ManifestLink
Required parameter. Link to the the version-manifest.json file
.PARAMETER VersionFilterToInclude
Optional parameter. List of filters to include particular versions
.PARAMETER VersionFilterToExclude
Optional parameter. List of filters to exclude particular versions
.PARAMETER RetryIntervalSec
Optional parameter. Retry interval in seconds
.PARAMETER RetryCount
Optional parameter. Retry count
#>

param (
    [Parameter(Mandatory)] [string] $ToolName
)

Import-Module "$PSScriptRoot/parsers/parsers-factory.psm1"

$ToolVersionParser = Get-ToolVersionsParser -ToolName $ToolName
$VersionsFromDist = $ToolVersionParser.GetAvailableVersions()
$VersionsFromManifest = $ToolVersionParser.GetUploadedVersions()

Write-Host "Dist"
$VersionsFromDist | ForEach-Object { Write-Host $_ }
Write-Host "Manifest"
$VersionsFromManifest | ForEach-Object { Write-Host $_ }

$VersionsToBuild = $VersionsFromDist | Where-Object { $VersionsFromManifest -notcontains $_ }

if ($VersionsToBuild) {
    $availableVersions = $VersionsToBuild -join ","
    $toolVersions = $availableVersions.Replace(",",", ")
    Write-Host "The following versions are available to build:`n$toolVersions"
    Write-Host "##vso[task.setvariable variable=TOOL_VERSIONS;isOutput=true]$toolVersions"
} else {
    Write-Host "There aren't versions to build"
}
