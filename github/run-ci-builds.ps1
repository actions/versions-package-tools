<#
.SYNOPSIS
Trigger runs on the workflow_dispatch event to build and upload tool packages

.PARAMETER RepositoryFullName
Required parameter. The owner and repository name. For example, 'actions/versions-package-tools'
.PARAMETER AccessToken
Required parameter. PAT Token to authorize
.PARAMETER WorkflowFileName
Required parameter. The name of workflow file that will be triggered
.PARAMETER WorkflowDispatchRef
Required parameter. The reference of the workflow run. The reference can be a branch, tag, or a commit SHA.
.PARAMETER ToolVersions
Required parameter. List of tool versions to build and upload
.PARAMETER PublishReleases
Required parameter. Whether to publish releases, true or false
#>

param (
    [Parameter(Mandatory)] [string] $RepositoryFullName,
    [Parameter(Mandatory)] [string] $AccessToken,
    [Parameter(Mandatory)] [string] $WorkflowFileName,
    [Parameter(Mandatory)] [string] $WorkflowDispatchRef,
    [Parameter(Mandatory)] [string] $ToolVersions,
    [Parameter(Mandatory)] [string] $PublishReleases
)

Import-Module (Join-Path $PSScriptRoot "github-api.psm1")

function Get-WorkflowRunLink {
    param(
        [Parameter(Mandatory)] [object] $GitHubApi,
        [Parameter(Mandatory)] [string] $WorkflowFileName,
        [Parameter(Mandatory)] [string] $ToolVersion
    )

    $listWorkflowRuns = $GitHubApi.GetWorkflowRuns($WorkflowFileName).workflow_runs | Sort-Object -Property 'run_number' -Descending

    foreach ($workflowRun in $listWorkflowRuns) {
        $workflowRunJob = $gitHubApi.GetWorkflowRunJobs($workflowRun.id).jobs | Select-Object -First 1

        if ($workflowRunJob.name -match $ToolVersion) {
            return $workflowRun.html_url
        }
    }

    return $null
}

function Queue-Builds {
    param (
        [Parameter(Mandatory)] [object] $GitHubApi,
        [Parameter(Mandatory)] [string] $ToolVersions,
        [Parameter(Mandatory)] [string] $WorkflowFileName,
        [Parameter(Mandatory)] [string] $WorkflowDispatchRef,
        [Parameter(Mandatory)] [string] $PublishReleases
    )

    $inputs = @{
        PUBLISH_RELEASES = $PublishReleases
    }
    
    $ToolVersions.Split(',') | ForEach-Object { 
        $version = $_.Trim()
        $inputs.VERSION = $version

        Write-Host "Queue build for $version..."
        $GitHubApi.CreateWorkflowDispatch($WorkflowFileName, $WorkflowDispatchRef, $inputs)

        Start-Sleep -s 10
        $workflowRunLink = Get-WorkflowRunLink -GitHubApi $GitHubApi `
                                               -WorkflowFileName $WorkflowFileName `
                                               -ToolVersion $version

        if (-not $workflowRunLink) {
            Write-Host "Could not find build for $version..."
            exit 1
        }

        Write-Host "Link to the build: $workflowRunLink"
    }
}

$gitHubApi = Get-GitHubApi -RepositoryName $RepositoryFullName -AccessToken $AccessToken

Write-Host "Versions to build: $ToolVersions"
Queue-Builds -GitHubApi $gitHubApi `
             -ToolVersions $ToolVersions `
             -WorkflowFileName $WorkflowFileName `
             -WorkflowDispatchRef $WorkflowDispatchRef `
             -PublishReleases $PublishReleases 
