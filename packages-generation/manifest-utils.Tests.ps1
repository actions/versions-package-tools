#Requires -Modules Pester
#Requires -Modules Assert

Import-Module (Join-Path $PSScriptRoot "manifest-utils.psm1") -Force
  
Describe "New-AssetItem" {
    It "use regex to parse all values in correct order" {
        $githubAsset = @{ name = "python-3.8.3-linux-16.04-x64.tar.gz"; browser_download_url = "long_url"; }
        $configuration = @{
            regex = "python-\d+\.\d+\.\d+-(\w+)-([\w\.]+)?-?(x\d+)";
            groups = [PSCustomObject]@{ platform = 1; platform_version = 2; arch = 3; };
        }
        $expectedOutput = [PSCustomObject]@{
            filename = "python-3.8.3-linux-16.04-x64.tar.gz"; platform = "linux"; platform_version = "16.04";
            arch = "x64"; download_url = "long_url";
        }

        $actualOutput = New-AssetItem -ReleaseAsset $githubAsset -Configuration $configuration
        Assert-Equivalent -Actual $actualOutput -Expected $expectedOutput
    }

    It "support constant values in groups" {
        $githubAsset = @{ name = "python-3.8.3-linux-16.04-x64.tar.gz"; browser_download_url = "long_url"; }
        $configuration = @{
            regex = "python-\d+\.\d+\.\d+-(\w+)-([\w\.]+)?-?(x\d+)";
            groups = [PSCustomObject]@{ platform = 1; platform_version = 2; arch = "x64"; }
        }
        $expectedOutput = [PSCustomObject]@{
            filename = "python-3.8.3-linux-16.04-x64.tar.gz"; platform = "linux"; platform_version = "16.04";
            arch = "x64"; download_url = "long_url";
        }

        $actualOutput = New-AssetItem -ReleaseAsset $githubAsset -Configuration $configuration
        Assert-Equivalent -Actual $actualOutput -Expected $expectedOutput
    }

    It "Skip empty groups" {
        $githubAsset = @{ name = "python-3.8.3-win32-x64.zip"; browser_download_url = "long_url"; }
        $configuration = @{
            regex = "python-\d+\.\d+\.\d+-(\w+)-([\w\.]+)?-?(x\d+)";
            groups = [PSCustomObject]@{ platform = 1; platform_version = 2; arch = 3; }
        }
        $expectedOutput = [PSCustomObject]@{
            filename = "python-3.8.3-win32-x64.zip"; platform = "win32";
            arch = "x64"; download_url = "long_url";
        }

        $actualOutput = New-AssetItem -ReleaseAsset $githubAsset -Configuration $configuration
        Assert-Equivalent -Actual $actualOutput -Expected $expectedOutput
    }
}

Describe "Get-VersionFromRelease" {
    It "clear version" {
        $release = @{ name = "3.8.3" }
        Get-VersionFromRelease -Release $release | Should -Be "3.8.3"
    }

    It "version with title" {
        $release = @{ name = "3.8.3: Release title" }
        Get-VersionFromRelease -Release $release | Should -Be "3.8.3"
    }

    It "take alpha, beta or rc version" {
        $release = @{ name = "3.8.3-alpha.1"}
        Get-VersionFromRelease -Release $release | Should -Be "3.8.3-alpha.1"

        $release = @{ name = "3.8.3-beta.2"}
        Get-VersionFromRelease -Release $release | Should -Be "3.8.3-beta.2"

        $release = @{ name = "3.8.3-rc.1"}
        Get-VersionFromRelease -Release $release | Should -Be "3.8.3-rc.1"
    }
}

Describe "Build-VersionsManifest" {
    $assets = @(
        @{ name = "python-3.8.3-linux-16.04-x64.tar.gz"; browser_download_url = "fake_url"; }
        @{ name = "python-3.8.3-linux-18.04-x64.tar.gz"; browser_download_url = "fake_url"; }
    )
    $configuration = @{
        regex = "python-\d+\.\d+\.\d+-(\w+)-([\w\.]+)?-?(x\d+)";
        groups = [PSCustomObject]@{ platform = 1; platform_version = 2; arch = "x64"; }
    }
    $expectedManifestFiles = @(
        [PSCustomObject]@{ filename = "python-3.8.3-linux-16.04-x64.tar.gz"; arch = "x64"; platform = "linux"; platform_version = "16.04"; download_url = "fake_url" },
        [PSCustomObject]@{ filename = "python-3.8.3-linux-18.04-x64.tar.gz"; arch = "x64"; platform = "linux"; platform_version = "18.04"; download_url = "fake_url" }
    )

    It "build manifest with correct version order" {
        $releases = @(
            @{ name = "3.8.1-beta.2"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-14T09:54:06Z"; assets = $assets },
            @{ name = "3.5.2: Hello"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:45:36Z"; assets = $assets },
            @{ name = "3.8.3-alpha.1"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.8.1-rc.1"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.8.1-beta.1"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.4.7"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.8.1-alpha.3"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.8.1-beta.12"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.5.2-beta.2"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
            @{ name = "3.8.1"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
        )
        $expectedManifest = @(
            [PSCustomObject]@{ version = "3.8.3-alpha.1"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles },
            [PSCustomObject]@{ version = "3.8.1"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFiles },
            [PSCustomObject]@{ version = "3.8.1-rc.1"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.8.1-beta.12"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.8.1-beta.2"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.8.1-beta.1"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.8.1-alpha.3"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.5.2"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.5.2-beta.2"; stable = $false; release_url = "fake_html_url"; files = $expectedManifestFiles }
            [PSCustomObject]@{ version = "3.4.7"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFiles }
        )
        $actualManifest = Build-VersionsManifest -Releases $releases -Configuration $configuration
        Assert-Equivalent -Actual $actualManifest -Expected $expectedManifest
    }

    It "Skip draft and prerelease" {
        $releases = @(
            @{ name = "3.8.1"; draft = $true; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-14T09:54:06Z"; assets = $assets },
            @{ name = "3.5.2"; draft = $false; prerelease = $true; html_url = "fake_html_url"; published_at = "2020-05-06T11:45:36Z"; assets = $assets },
            @{ name = "3.8.3"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
        )
        $expectedManifest = @(
            [PSCustomObject]@{ version = "3.8.3"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFiles }
        )
        [array]$actualManifest = Build-VersionsManifest -Releases $releases -Configuration $configuration
        Assert-Equivalent -Actual $actualManifest -Expected $expectedManifest
    }

    It "take latest published release for each version" {
        $releases = @(
            @{ name = "3.8.1"; draft = $false; prerelease = $false; html_url = "fake_html_url1"; published_at = "2020-05-06T11:45:36Z"; assets = $assets },
            @{ name = "3.8.1"; draft = $false; prerelease = $false; html_url = "fake_html_url2"; published_at = "2020-05-14T09:54:06Z"; assets = $assets },
            @{ name = "3.8.1"; draft = $false; prerelease = $false; html_url = "fake_html_url3"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
        )
        $expectedManifest = @(
            [PSCustomObject]@{ version = "3.8.1"; stable = $true; release_url = "fake_html_url2"; files = $expectedManifestFiles }
        )
        [array]$actualManifest = Build-VersionsManifest -Releases $releases -Configuration $configuration
        Assert-Equivalent -Actual $actualManifest -Expected $expectedManifest
    }

    It "build correct manifest if release includes one asset" {
        $asset = @(
            @{ name = "python-3.8.3-linux-16.04-x64.tar.gz"; browser_download_url = "fake_url"; }
        )
        $expectedManifestFile = @(
            [PSCustomObject]@{ filename = "python-3.8.3-linux-16.04-x64.tar.gz"; arch = "x64"; platform = "linux"; platform_version = "16.04"; download_url = "fake_url" }
        )
        
        $releases = @(
            @{ name = "3.8.3"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $asset },
            @{ name = "3.8.1"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-14T09:54:06Z"; assets = $assets }
        )
        $expectedManifest = @(
            [PSCustomObject]@{ version = "3.8.3"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFile },
            [PSCustomObject]@{ version = "3.8.1"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFiles }
        )
        [array]$actualManifest = Build-VersionsManifest -Releases $releases -Configuration $configuration
        Assert-Equivalent -Actual $actualManifest -Expected $expectedManifest
    }

    It "set correct lts value for versions" {
        $releases = @(
            @{ name = "14.2.1"; draft = false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-14T09:54:06Z"; assets = $assets },
            @{ name = "12.0.1"; draft = $false; prerelease = false; html_url = "fake_html_url"; published_at = "2020-05-06T11:45:36Z"; assets = $assets },
            @{ name = "16.2.2"; draft = $false; prerelease = $false; html_url = "fake_html_url"; published_at = "2020-05-06T11:43:38Z"; assets = $assets }
        )
        $configuration = @{
            regex = "python-\d+\.\d+\.\d+-(\w+)-([\w\.]+)?-?(x\d+)";
            groups = [PSCustomObject]@{ platform = 1; platform_version = 2; arch = "x64"; }
            lts_rule_expression = "@(@{ Name = '14'; Value = 'Fermium' }, @{ Name = '12'; Value = 'Erbium' })"
        }
        $expectedManifest = @(
            [PSCustomObject]@{ version = "16.2.2"; stable = $true; release_url = "fake_html_url"; files = $expectedManifestFiles },
            [PSCustomObject]@{ version = "14.2.1"; stable = $true; lts = "Fermium"; release_url = "fake_html_url"; files = $expectedManifestFiles },
            [PSCustomObject]@{ version = "12.0.1"; stable = $true; lts = "Erbium"; release_url = "fake_html_url"; files = $expectedManifestFiles }
        )
        [array]$actualManifest = Build-VersionsManifest -Releases $releases -Configuration $configuration
        Assert-Equivalent -Actual $actualManifest -Expected $expectedManifest
    }
}

Describe "Get-VersionLtsStatus" {
    $ltsRules = @(
        @{ Name = "14"; Value = "Fermium" },
        @{ Name = "12"; Value = "Erbium" },
        @{ Name = "10"; Value = $true },
        @{ Name = "8.3"; Value = "LTS 8.3" }
    )

    It "lts label is matched" {
        Get-VersionLtsStatus -Version "14.2.2" -LtsRules $ltsRules | Should -Be "Fermium"
        Get-VersionLtsStatus -Version "12.3.1" -LtsRules $ltsRules | Should -Be "Erbium"
        Get-VersionLtsStatus -Version "10.8.1" -LtsRules $ltsRules | Should -Be $true
        Get-VersionLtsStatus -Version "8.3.2" -LtsRules $ltsRules | Should -Be "LTS 8.3"
        Get-VersionLtsStatus -Version "14" -LtsRules $ltsRules | Should -Be "Fermium"
    }

    It "lts label is not matched" {
        Get-VersionLtsStatus -Version "9.1" -LtsRules $ltsRules | Should -Be $null
        Get-VersionLtsStatus -Version "13.8" -LtsRules $ltsRules | Should -Be $null
        Get-VersionLtsStatus -Version "5" -LtsRules $ltsRules | Should -Be $null
        Get-VersionLtsStatus -Version "8.4" -LtsRules $ltsRules | Should -Be $null
        Get-VersionLtsStatus -Version "142.5.1" -LtsRules $ltsRules | Should -Be $null
    }

    It "no rules" {
        Get-VersionLtsStatus -Version "14.2.2" | Should -Be $null
        Get-VersionLtsStatus -Version "12.3.1" -LtsRules $null | Should -Be $null
    }
}