using module "./base-parser.psm1"

class PythonVersionsParser: BaseVersionsParser {
    [SemVer[]] GetUploadedVersions() {
        $url = $this.BuildGitHubFileUrl("actions", "python-versions", "main", "versions-manifest.json")
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        return $releases.version
    }

    hidden [string[]] ParseAllAvailableVersions() {
        $stableVersionsUrl = "https://www.python.org/ftp/python"
        $stableVersionsHtmlRaw = Invoke-WebRequest $stableVersionsUrl
        $stableVersionsList = $stableVersionsHtmlRaw.Links.href | Where-Object {
            $parsed = $null
            return $_.EndsWith("/") -and [SemVer]::TryParse($_.Replace("/", ""), [ref]$parsed)
        }

        return $stableVersionsList | ForEach-Object {
            $subVersionsUrl = "${stableVersionsUrl}/${_}"
            $subVersionsHtmlRaw = Invoke-WebRequest $subVersionsUrl
            return $subVersionsHtmlRaw.Links.href | ForEach-Object {
                if ($_ -match "^Python-(\d+\.\d+\.\d+[a-z]{0,2}\d*)\.tgz$") {
                    return $Matches[1]
                }
            } | ForEach-Object { $_ } | Where-Object { $_ }
        }
    }

    hidden [SemVer] FormatVersion([string]$VersionSpec) {
        $VersionSpec -match "^(\d+)\.(\d+)\.(\d+)([a-z]{1,2})?(\d+)?$"
        
        if ($Matches.Count -gt 4) {
            $VersionLabel = "{0}.{1}" -f $this.ConvertPythonLabel($Matches[4]), $Matches[5]
            return [SemVer]::new($Matches[1], $Matches[2], $Matches[3], $VersionLabel)
        }

        return [SemVer]::new($Matches[1], $Matches[2], $Matches[3])
    }

    hidden [string] ConvertPythonLabel([string]$Label) {
        switch ($Label) {
            "a" { return "alpha" }
            "b" { return "beta" }
            "rc" { return "rc" }
        }

        return $Label
    }

    [bool] ShouldIncludeVersion([SemVer]$Version) {
        # For Go, we include all versions greater than 1.12
        return $Version -gt [SemVer]"3.9.0"
    }
}