using module "./base-parser.psm1"

class GoVersionsParser: BaseVersionsParser {
    [SemVer[]] GetUploadedVersions() {
        $url = $this.BuildGitHubFileUrl("actions", "go-versions", "main", "versions-manifest.json")
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        return $releases.version
    }

    hidden [string[]] ParseAllAvailableVersions() {
        $url = "https://golang.org/dl/?mode=json&include=all"
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        return $releases.version
    }

    hidden [SemVer] FormatVersion([string]$VersionSpec) {
        $cleanVersion = $VersionSpec -replace "^go", ""
        return [SemVer]$cleanVersion
    }

    hidden [bool] ShouldIncludeVersion([SemVer]$Version) {
        # For Go, we include all versions greater than 1.12
        return $Version -gt [SemVer]"1.12.0"
    }
}