<#
.SYNOPSIS
Generate versions manifest based on repository releases
.DESCRIPTION
Versions manifest is needed to find the latest assets for particular version of tool
.PARAMETER RepositoryFullName
Required parameter. The owner and repository name. For example, 'actions/versions-package-tools'
.PARAMETER GitHubAccessToken
Required parameter. PAT Token to overcome GitHub API Rate limit
.PARAMETER OutputFile
Required parameter. File "*.json" where generated results will be saved
.PARAMETER ConfigurationFile
Path to the json file with parsing configuration
#>

param (
    [Parameter(Mandatory)] [string] $RepositoryFullName,
    [Parameter(Mandatory)] [string] $GitHubAccessToken,
    [Parameter(Mandatory)] [string] $OutputFile,
    [Parameter(Mandatory)] [string] $ConfigurationFile
)

Import-Module (Join-Path $PSScriptRoot "../github/github-api.psm1")
Import-Module (Join-Path $PSScriptRoot "manifest-utils.psm1") -Force

$configuration = Read-ConfigurationFile -Filepath $ConfigurationFile

$gitHubApi = Get-GitHubApi -RepositoryFullName $RepositoryFullName -AccessToken $GitHubAccessToken
$releases = $gitHubApi.GetReleases()
$versionIndex = Build-VersionsManifest -Releases $releases -Configuration $configuration
$versionIndex | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding UTF8NoBOM -Force
