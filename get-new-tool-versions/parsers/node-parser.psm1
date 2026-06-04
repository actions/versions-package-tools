using module "./base-parser.psm1"

class NodeVersionsParser: BaseVersionsParser {
    [SemVer[]] GetUploadedVersions() {
        $url = $this.BuildGitHubFileUrl("actions", "node-versions", "main", "versions-manifest.json")
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        return $releases.version
    }

    hidden [string[]] ParseAllAvailableVersions() {
        $url = "https://nodejs.org/dist/index.json"
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        return $releases.version
    }

    hidden [SemVer] FormatVersion([string]$VersionSpec) {
        $cleanVersion = $VersionSpec -replace "^v", ""
        return [SemVer]$cleanVersion
    }

    hidden [bool] ShouldIncludeVersion([SemVer]$Version) {
        if ($Version.Major -lt 8) {
            return $false
        }
        elseif ($Version.Major -lt 27)
        {
            # For Node.JS, we should include all LTS versions (all even-numbered releases)
            # https://nodejs.org/en/about/releases/
            return $Version.Major % 2 -eq 0
        }
        else
        {
            # https://nodejs.org/en/blog/announcements/evolving-the-nodejs-release-schedule
            return $true
        }
    }
}
