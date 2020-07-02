#Requires -Modules Pester

Import-Module (Join-Path $PSScriptRoot "helpers.psm1") -Force
  
Describe "Validate-FiltersFormat" {
    It "Filter with word" {
        { Validate-FiltersFormat -Filters @("1two.2") } | Should -Throw "Invalid filter format"
    }

    It "Filter with non-word character" {
        { Validate-FiltersFormat -Filters @("1,.2") } | Should -Throw "Invalid filter format"
    }

    It "Valid filters" {
        { Validate-FiltersFormat -Filters @("*", "1", "1.*", "1.2", "1.2.*") } | Should -Not -Throw "Invalid filter format"
    }
}

Describe "Format-Versions" {
    It "Clean versions" {
        $actualOutput = Format-Versions -Versions @("14.2.0", "1.14.0")
        $expectedOutput = @("14.2.0", "1.14.0")
        $actualOutput | Should -Be $expectedOutput
    }

    It "Versions with prefixes" {
        $actualOutput = Format-Versions -Versions @("v14.2.0", "go1.14.0")
        $expectedOutput = @("14.2.0", "1.14.0")
        $actualOutput | Should -Be $expectedOutput
    }

    It "Skip beta and rc versions" {
        $actualOutput = Format-Versions -Versions @("14.2.0-beta", "v1.14.0-rc-1")
        $expectedOutput = @()
        $actualOutput | Should -Be $expectedOutput
    }
    
    It "Short version" {
        $actualOutput = Format-Versions -Versions @("14.2", "v2.0")
        $expectedOutput = @("14.2.0", "2.0.0")
        $actualOutput | Should -Be $expectedOutput
    }

    It "Skip versions with 1 digit" {
        $actualOutput = Format-Versions -Versions @("14", "v2")
        $expectedOutput = @()
        $actualOutput | Should -Be $expectedOutput
    }
}

Describe "Select-VersionsByFilter" {
    $inputVersions = @("8.2.1", "9.3.3", "10.0.2", "10.0.3", "10.5.6", "12.4.3", "12.5.1", "14.2.0")

    It "Include filter only" {
        $includeFilters = @("8.*", "14.*")
        $excludeFilters = @()
        $actualOutput = Select-VersionsByFilter -Versions $inputVersions -IncludeFilters $includeFilters -ExcludeFilters $excludeFilters
        $expectedOutput = @("8.2.1", "14.2.0")
        $actualOutput | Should -Be $expectedOutput
    }

    It "Include and exclude filters" {
        $includeFilters = @("10.*", "12.*")
        $excludeFilters = @("10.0.*", "12.4.3")
        $actualOutput = Select-VersionsByFilter -Versions $inputVersions -IncludeFilters $includeFilters -ExcludeFilters $excludeFilters
        $expectedOutput = @("10.5.6", "12.5.1")
        $actualOutput | Should -Be $expectedOutput
    }

    It "Exclude filter only" {
        $includeFilters = @()
        $excludeFilters = @("10.*", "12.*")
        $actualOutput = Select-VersionsByFilter -Versions $inputVersions -IncludeFilters $includeFilters -ExcludeFilters $excludeFilters
        $expectedOutput = @("8.2.1", "9.3.3", "14.2.0")
        $actualOutput | Should -Be $expectedOutput
    }

    It "Include and exclude filters are empty" {
        $actualOutput = Select-VersionsByFilter -Versions $inputVersions
        $expectedOutput = @("8.2.1", "9.3.3", "10.0.2", "10.0.3", "10.5.6", "12.4.3", "12.5.1", "14.2.0")
        $actualOutput | Should -Be $expectedOutput
    }
}

Describe "Skip-ExistingVersions" {
    It "Substract versions correctly" {
        $distInput = @("14.2.0", "14.3.0", "14.4.0", "14.4.1")
        $manifestInput = @("12.0.0", "14.2.0", "14.4.0")
        $actualOutput =  Skip-ExistingVersions -VersionsFromDist $distInput -VersionsFromManifest $manifestInput
        $expectedOutput = @("14.3.0", "14.4.1")
        $actualOutput | Should -Be $expectedOutput
    }
}