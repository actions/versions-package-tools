<#
.SYNOPSIS
The module that contains a bunch of methods to interact with GitHub API V3
#>
class GitHubApi
{
    [string] $BaseUrl
    [object] $AuthHeader

    GitHubApi(
        [string] $AccountName,
        [string] $ProjectName,
        [string] $AccessToken
    ) {
        $this.BaseUrl = $this.BuildBaseUrl($AccountName, $ProjectName)
        $this.AuthHeader = $this.BuildAuth($AccessToken)
    }

    [object] hidden BuildAuth([string]$AccessToken) {
        if ([string]::IsNullOrEmpty($AccessToken)) {
            return $null
        }
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("'':${AccessToken}"))
        return @{
            Authorization = "Basic ${base64AuthInfo}"
        }
    }

    [string] hidden BuildBaseUrl([string]$RepositoryOwner, [string]$RepositoryName) {
        return "https://api.github.com/repos/$RepositoryOwner/$RepositoryName"
    }

    [object] CreateNewPullRequest([string]$Title, [string]$Body, [string]$BranchName){
        $requestBody = @{
            title = $Title
            body = $Body
            head = $BranchName
            base = "main"
        } | ConvertTo-Json

        $url = "pulls"
        return $this.InvokeRestMethod($url, 'Post', $null, $requestBody)
    }

    [object] GetPullRequest([string]$BranchName, [string]$RepositoryOwner){
        $url = "pulls"
        return $this.InvokeRestMethod($url, 'GET', "head=${RepositoryOwner}:$BranchName&base=main", $null)
    }

    [object] UpdatePullRequest([string]$Title, [string]$Body, [string]$BranchName, [string]$PullRequestNumber){
        $requestBody = @{
            title = $Title
            body = $Body
            head = $BranchName
            base = "main"
        } | ConvertTo-Json

        $url = "pulls/$PullRequestNumber"
        return $this.InvokeRestMethod($url, 'Post', $null, $requestBody)
    }

    [array] GetReleases(){
        $url = "releases"
        $releases = @()
        $pageNumber = 1
        $releaseNumberLimit = 10000

        while ($releases.Count -le $releaseNumberLimit)
        {
            $requestParams = "page=${pageNumber}&per_page=100"
            [array] $response = $this.InvokeRestMethod($url, 'GET', $requestParams, $null)
            
            if ($response.Count -eq 0) {
                break
            } else {
                $releases += $response
                $pageNumber++
            }
        }

        return $releases
    }

    [void] DispatchWorkflow([string]$EventType) {
        $url = "dispatches"
        $body = @{
            event_type = $EventType
        } | ConvertTo-Json

        $this.InvokeRestMethod($url, 'POST', $null, $body)
    }

    [object] GetWorkflowRuns([string]$WorkflowFileName) {
        $url = "actions/workflows/$WorkflowFileName/runs"
        return $this.InvokeRestMethod($url, 'GET', $null, $null)
    }

    [object] GetWorkflowRunJobs([string]$WorkflowRunId) {
        $url = "actions/runs/$WorkflowRunId/jobs"
        return $this.InvokeRestMethod($url, 'GET', $null, $null)
    }

    [void] CreateWorkflowDispatch([string]$WorkflowFileName, [string]$Ref, [object]$Inputs) {
        $url = "actions/workflows/${WorkflowFileName}/dispatches"
        $body = @{
            ref = $Ref
            inputs = $Inputs
        } | ConvertTo-Json

        $this.InvokeRestMethod($url, 'POST', $null, $body)
    }

    [string] hidden BuildUrl([string]$Url, [string]$RequestParams) {
        if ([string]::IsNullOrEmpty($RequestParams)) {
            return "$($this.BaseUrl)/$($Url)"
        } else {
            return "$($this.BaseUrl)/$($Url)?$($RequestParams)"
        }
    }

    [object] hidden InvokeRestMethod(
        [string] $Url,
        [string] $Method,
        [string] $RequestParams,
        [string] $Body
    ) {
        $requestUrl = $this.BuildUrl($Url, $RequestParams)
        $params = @{
            Method = $Method
            ContentType = "application/json"
            Uri = $requestUrl
            Headers = @{}
        }
        if ($this.AuthHeader) {
            $params.Headers += $this.AuthHeader
        }
        if (![string]::IsNullOrEmpty($Body)) {
            $params.Body = $Body
        }

        return Invoke-RestMethod @params
    }

}

function Get-GitHubApi {
    param (
        [Parameter(ParameterSetName = 'RepositorySingle')]
        [string] $RepositoryFullName,
        [Parameter(ParameterSetName = 'RepositorySplitted')]
        [string] $RepositoryOwner,
        [Parameter(ParameterSetName = 'RepositorySplitted')]
        [string] $RepositoryName,
        [string] $AccessToken
    )

    if ($PSCmdlet.ParameterSetName -eq "RepositorySingle") {
        $RepositoryOwner, $RepositoryName = $RepositoryFullName.Split('/', 2)
    }

    return [GitHubApi]::New($RepositoryOwner, $RepositoryName, $AccessToken)
}