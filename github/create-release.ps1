<#
.SYNOPSIS
Trigger runs on the workflow_dispatch event to create tool release

.PARAMETER RepositoryFullName
Required parameter. The owner and repository name. For example, 'actions/versions-package-tools'
.PARAMETER AccessToken
Required parameter. PAT Token to authorize
.PARAMETER ToolVersion
Required parameter. Version of tool
.PARAMETER TagName
Required parameter. The name of the release tag
.PARAMETER ReleaseBody
Required parameter. Text describing the contents of the release
.PARAMETER EventType
Required parameter. The name of the repository dispatch event
#>

param (
    [Parameter(Mandatory)] [string] $RepositoryFullName,
    [Parameter(Mandatory)] [string] $AccessToken,
    [Parameter(Mandatory)] [string] $ToolVersion,
    [Parameter(Mandatory)] [string] $TagName,
    [Parameter(Mandatory)] [string] $ReleaseBody,
    [Parameter(Mandatory)] [string] $EventType,
    [UInt32] $RetryIntervalSec = 10,
    [UInt32] $RetryCount = 5
)

Import-Module (Join-Path $PSScriptRoot "github-api.psm1")

function Create-Release {
    param (
        [Parameter(Mandatory)] [object] $GitHubApi,
        [Parameter(Mandatory)] [string] $ToolVersion,
        [Parameter(Mandatory)] [string] $TagName,
        [Parameter(Mandatory)] [string] $ReleaseBody,
        [Parameter(Mandatory)] [string] $EventType
    )

    $eventPayload = @{
        ToolVersion = $ToolVersion
        TagName = $TagName
        ReleaseBody = $ReleaseBody
    }

    Write-Host "Create '$EventType' repository dispatch event"
    $GitHubApi.CreateRepositoryDispatch($EventType, $eventPayload)
}

function Validate-ReleaseAvailability {
    param (
        [Parameter(Mandatory)] [object] $GitHubApi,
        [Parameter(Mandatory)] [string] $TagName,
        [Parameter(Mandatory)] [UInt32] $RetryIntervalSec,
        [Parameter(Mandatory)] [UInt32] $RetryCount
    )

    do {
        $createdRelease = $GitHubApi.GetReleases() | Where-Object { $_.tag_name -eq $TagName }
        if ($createdRelease) {
            Write-Host "Release was successfully created: $($createdRelease.html_url)"
            return
        }

        $RetryCount--
        Start-Sleep -Seconds $RetryIntervalSec
    } while($RetryCount -gt 0)

    Write-Host "Release was not created"
    exit 1
}

$gitHubApi = Get-GitHubApi -RepositoryFullName $RepositoryFullName -AccessToken $AccessToken

Create-Release -GitHubApi $gitHubApi `
               -ToolVersion $ToolVersion `
               -TagName $TagName `
               -ReleaseBody $ReleaseBody `
               -EventType $EventType

Start-Sleep -s $RetryIntervalSec
Validate-ReleaseAvailability -GitHubApi $gitHubApi `
                             -TagName $TagName `
                             -RetryIntervalSec $RetryIntervalSec `
                             -RetryCount $RetryCount
