param (
    [Parameter(Mandatory)][string] $ManifestPath
)

$Global:validationFailed = $false

function Publish-Error {
    param(
        [string] $ErrorDescription,
        [object] $Exception
    )

    Write-Output "::error ::$ErrorDescription" 
    if (-not [string]::IsNullOrEmpty($Exception))
    {
        Write-Output "Exception: $Exception"
    }
    $Global:validationFailed = $true
}

function Test-DownloadUrl {
    param(
        [string] $DownloadUrl
    )

    $request = [System.Net.WebRequest]::Create($DownloadUrl)
    try {
        $response = $request.GetResponse()
        return ([int]$response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

if (-not (Test-Path $ManifestPath)) {
    Publish-Error "Unable to find manifest json file at '$ManifestPath'"
    exit 1
}

Write-Host "Parsing manifest json content from '$ManifestPath'..."
try {
    $manifestJson = Get-Content $ManifestPath | ConvertFrom-Json
} catch {
    Publish-Error "Unable to parse manifest json content '$ManifestPath'" $_
    exit 1
}

$versionsList = $manifestJson.version
Write-Host "Found versions: $($versionsList -join ', ')"

$manifestJson | ForEach-Object {
    Write-Host "Validating version '$($_.version)'..."
    $_.files | ForEach-Object {
        Write-Host "    Validating '$($_.download_url)'..."
        if (-not (Test-DownloadUrl $_.download_url)) {
            Publish-Error "Url '$($_.download_url)' is invalid"
        }
    }
}

if ($Global:validationFailed) {
    exit 1
}
