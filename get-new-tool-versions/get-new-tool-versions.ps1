<#
.SYNOPSIS
Check and return list of new available tool versions

.PARAMETER ToolName
Required parameter. The name of tool for which parser is available (Node, Go, Python)
#>

param (
    [Parameter(Mandatory)] [string] $ToolName
)

Import-Module "$PSScriptRoot/parsers/parsers-factory.psm1"

$ToolVersionParser = Get-ToolVersionsParser -ToolName $ToolName
$VersionsFromDist = $ToolVersionParser.GetAvailableVersions()
$VersionsFromManifest = $ToolVersionParser.GetUploadedVersions()

$VersionsToBuild = $VersionsFromDist | Where-Object { $VersionsFromManifest -notcontains $_ }

if ($VersionsToBuild) {
    $availableVersions = $VersionsToBuild -join ", "
    Write-Host "The following versions are available to build:`n${availableVersions}"
    Write-Host "::set-output name=TOOL_VERSIONS::${availableVersions}"
    Write-Host "##vso[task.setvariable variable=TOOL_VERSIONS;isOutput=true]${availableVersions}"
} else {
    Write-Host "There aren't versions to build"
}
