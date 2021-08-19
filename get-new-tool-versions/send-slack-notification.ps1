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

    [System.String]$ToolVersion,
    [System.String]$PipelineUrl,
    [System.String]$ImageUrl = 'https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png',
    [System.String]$Text
)

# Import helpers module
Import-Module $PSScriptRoot/helpers.psm1 -DisableNameChecking

# Create JSON body
if ([string]::IsNullOrWhiteSpace($Text)) {
    if ($toolName -eq "Xamarin") {
        $Text = "The following versions of '$toolName' are available, consider adding them to toolset: $toolVersion"
    } else {
        $Text = "The following versions of '$toolName' are available to upload: $toolVersion"
    }
    if (-not ([string]::IsNullOrWhiteSpace($PipelineUrl))) {
        $Text += "\nLink to the pipeline: $pipelineUrl"
    }
}
$jsonBodyMessage = @"
{
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "$Text"
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
