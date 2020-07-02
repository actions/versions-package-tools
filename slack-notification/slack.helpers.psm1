<#
.SYNOPSIS
Sending messages using Incoming Webhooks
https://api.slack.com/messaging/webhooks
#>

function Send-SlackPostMessageIncomingWebHook
{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Uri]$Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Object]$Body
    )

    try
    {
        $response = Invoke-RestMethod -Uri $uri -Method POST -Body $body -ErrorAction Stop
        if ($response -eq 'ok')
        {
            return $response
        }
        else
        {
            Write-Host "##vso[task.LogIssue type=error;] Something went wrong. Response is '$response'"
        }
    }
    catch
    {
        Write-Host "##vso[task.LogIssue type=error;] Slack send post message failed: '$_'"
    }

    Write-Host "##vso[task.complete result=Failed;]"
    exit 1
}