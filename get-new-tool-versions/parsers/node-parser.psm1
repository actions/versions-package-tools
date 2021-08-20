using module "./base-parser.psm1"

class NodeVersionsParser: BaseVersionsParser {
    [SemVer[]] GetUploadedVersions() {
        $url = $this.BuildGitHubFileUrl("nikita-bykov", "node-versions", "move-get-node-versions-test", "versions-manifest.json")
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

        # For Node.JS, we should include all LTS versions (all even-numbered releases)
        # https://nodejs.org/en/about/releases/
        return $Version.Major % 2 -eq 0
    }
}