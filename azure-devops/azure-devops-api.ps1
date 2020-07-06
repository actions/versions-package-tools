class AzureDevOpsApi
{
    [string] $BaseUrl
    [string] $RepoOwner
    [object] $AuthHeader
    [UInt32] $RetryCount
    [UInt32] $RetryIntervalSec

    AzureDevOpsApi(
        [string] $TeamFoundationCollectionUri,
        [string] $ProjectName,
        [string] $AccessToken,
        [UInt32] $RetryCount,
        [UInt32] $RetryIntervalSec
    ) {
        $this.BaseUrl = $this.BuildBaseUrl($TeamFoundationCollectionUri, $ProjectName)
        $this.AuthHeader = $this.BuildAuth($AccessToken)
        $this.RetryCount = $RetryCount
        $this.RetryIntervalSec = $RetryIntervalSec
    }

    [object] hidden BuildAuth([string]$AccessToken) {
        if ([string]::IsNullOrEmpty($AccessToken)) {
            return $null
        }
        return @{
            Authorization = "Bearer $AccessToken"
        }
    }

    [string] hidden BuildBaseUrl([string]$TeamFoundationCollectionUri, [string]$ProjectName) {
        return "${TeamFoundationCollectionUri}/${ProjectName}/_apis"
    }

    [object] QueueBuild([string]$ToolVersion, [string]$SourceBranch, [string]$SourceVersion, [UInt32]$DefinitionId){
        $url = "build/builds"
        
        # The content of parameters field should be a json string
        $buildParameters = @{ VERSION = $ToolVersion } | ConvertTo-Json

        $body = @{
            definition = @{
                id = $DefinitionId
            }
            sourceBranch = $SourceBranch
            sourceVersion = $SourceVersion
            parameters = $buildParameters
        } | ConvertTo-Json

        return $this.InvokeRestMethod($url, 'POST', $body)
    }

    [object] GetBuildInfo([UInt32]$BuildId){
        $url = "build/builds/$BuildId"

        return $this.InvokeRestMethod($url, 'GET', $null)
    }

    [object] UpdateBuildStatus([UInt32]$BuildId, [string]$BuildStatus){
        $url = "build/builds/$BuildId"
        $body = @{ 
            status = $BuildStatus 
        } | ConvertTo-Json

        return $this.InvokeRestMethod($url, 'PATCH', $body)
    }

    [string] hidden BuildUrl([string]$Url) {
        return "$($this.BaseUrl)/${Url}/?api-version=5.1"
    }

    [object] hidden InvokeRestMethod(
        [string] $Url,
        [string] $Method,
        [string] $Body
    ) {
        $requestUrl = $this.BuildUrl($Url)
        $params = @{
            Method = $Method
            ContentType = "application/json"
            Uri = $requestUrl
            Headers = @{}
        }
        if ($this.AuthHeader) {
            $params.Headers += $this.AuthHeader
        }
        if (![string]::IsNullOrEmpty($body)) {
            $params.Body = $Body
        }

        $params.RetryIntervalSec = $this.RetryIntervalSec
        $params.MaximumRetryCount = $this.RetryCount

        return Invoke-RestMethod @params
    }
}

function Get-AzureDevOpsApi {
    param (
        [string] $TeamFoundationCollectionUri,
        [string] $ProjectName,
        [string] $AccessToken,
        [UInt32] $RetryCount = 3,
        [UInt32] $RetryIntervalSec = 60
    )

    return [AzureDevOpsApi]::New($TeamFoundationCollectionUri, $ProjectName, $AccessToken, $RetryCount, $RetryIntervalSec)
}