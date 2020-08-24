<#
.SYNOPSIS
Pester extension that allows to run command and validate exit code
.EXAMPLE
"python file.py" | Should -ReturnZeroExitCode
#>
function ShouldReturnZeroExitCode {
    Param(
        [String] $ActualValue,
        [switch] $Negate,
        [string] $Because # This parameter is unused by we need it to match Pester asserts signature
    )

    $result = Get-CommandResult $ActualValue

    [bool]$succeeded = $result.ExitCode -eq 0
    if ($Negate) { $succeeded = -not $succeeded }

    if (-not $succeeded)
    {
        $commandOutputIndent = " " * 4
        $commandOutput = ($result.Output | ForEach-Object { "${commandOutputIndent}${_}" }) -join "`n"
        $failureMessage = "Command '${ActualValue}' has finished with exit code ${actualExitCode}`n${commandOutput}"
    }

    return [PSCustomObject] @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

if (Get-Command -Name Add-AssertionOperator -ErrorAction SilentlyContinue) {
    Add-AssertionOperator -Name ReturnZeroExitCode -InternalName ShouldReturnZeroExitCode -Test ${function:ShouldReturnZeroExitCode}
}
