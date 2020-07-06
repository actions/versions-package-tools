<#
.SYNOPSIS
Sending messages using Incoming Webhooks

.PARAMETER Url
Required parameter. Incoming Webhook URL to post a message
.PARAMETER ToolName
Required parameter. The name of tool
.PARAMETER ToolVersion
Required parameter. Specifies the version of tool
.PARAMETER PipelineUrl
Required parameter. The pipeline URL
.PARAMETER ImageUrl
Optional parameter. The image URL
#>

param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.Uri]$Url,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.String]$ToolName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.String]$ToolVersion,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [System.String]$PipelineUrl,

    [System.String]$ImageUrl = 'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png'
)

# Import helpers module
Import-Module $PSScriptRoot/helpers.psm1 -DisableNameChecking

# Create JSON body
$text = "The following versions of '$toolName' are available to upload: $toolVersion\nLink to the pipeline: $pipelineUrl"
$jsonBodyMessage = @"
{
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "$text"
            },
            "accessory": {
                "type": "image",
                "image_url": "$imageUrl",
                "alt_text": "$toolName"
            }
        }
    ]
}
"@

# Send Slack message
$null = Send-SlackPostMessageIncomingWebHook -Uri $url -Body $jsonBodyMessage
Write-Host "Message template: `n $jsonBodyMessage"
