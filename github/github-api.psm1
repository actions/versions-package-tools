<#
.SYNOPSIS
The module that contains a bunch of methods to interact with GitHub API V3
#>
class GitHubApi
{
    [string] $BaseUrl
    [object] $AuthHeader
    [string] $RepositoryOwner

    GitHubApi(
        [string] $AccountName,
        [string] $ProjectName,
        [string] $AccessToken
    ) {
        $this.BaseUrl = $this.BuildBaseUrl($AccountName, $ProjectName)
        $this.AuthHeader = $this.BuildAuth($AccessToken)
        $this.RepositoryOwner = $AccountName
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

    [object] GetPullRequest([string]$BranchName){
        $url = "pulls"
        return $this.InvokeRestMethod($url, 'GET', "head=$($this.RepositoryOwner):${BranchName}&base=main", $null)
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

    [void] CreateRepositoryDispatch([string]$EventType, [object]$EventPayload) {
        $url = "dispatches"
        $body = @{
            event_type = $EventType
            client_payload = $EventPayload
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
        $body = @{ ref = $Ref }
        
        if ($Inputs) {
            $body.inputs = $Inputs
        }

        $jsonBody = $body | ConvertTo-Json

        $this.InvokeRestMethod($url, 'POST', $null, $jsonBody)
    }

    [string] hidden BuildUrl([string]$Url, [string]$RequestParams) {
        if ([string]::IsNullOrEmpty($RequestParams)) {
            return "$($this.BaseUrl)/$($Url)"
        } else {
            return "$($this.BaseUrl)/$($Url)?$($RequestParams)"
        }
    }

    [void] CancelWorkflow([string]$WorkflowId) {
        $url = "actions/runs/$WorkflowId/cancel"
        $this.InvokeRestMethod($url, 'POST', $null, $null)
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