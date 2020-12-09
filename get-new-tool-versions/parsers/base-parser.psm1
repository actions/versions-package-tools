class BaseVersionsParser {
    [Int32]$ApiRetryCount = 3
    [Int32]$ApiRetryIntervalSeconds = 60

    [SemVer[]] GetAvailableVersions() {
        $allVersionsRaw = $this.ParseAllAvailableVersions()
        $allVersions = $allVersionsRaw | ForEach-Object { Write-Host $_; $this.FormatVersion($_) }
        $filteredVersions = $allVersions | Where-Object { $this.ShouldIncludeVersion($_) }
        return $filteredVersions
    }

    [SemVer[]] GetUploadedVersions() {
        throw "Method is not implemented in base class"
    }

    hidden [SemVer[]] ParseAllAvailableVersions() {
        throw "Method is not implemented in base class"
    }

    hidden [SemVer] FormatVersion([string]$VersionSpec) {
        throw "Method is not implemented in base class"
    }

    hidden [bool] ShouldIncludeVersion([SemVer]$Version) {
        throw "Method is not implemented in base class"
    }

    hidden [string] BuildGitHubFileUrl($OrganizationName, $RepositoryName, $BranchName, $FilePath) {
        # https://raw.githubusercontent.com/actions/node-versions/main/versions-manifest.json
        return "https://raw.githubusercontent.com/${OrganizationName}/${RepositoryName}/${BranchName}/${FilePath}"
    }
}