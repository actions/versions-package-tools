<#
.SYNOPSIS
Pester extension that allows to run command and validate exit code
.EXAMPLE
"python file.py" | Should -ReturnZeroExitCode
#>

function Get-CommandResult {
    Param (
        [Parameter(Mandatory=$true)]
        [string] $Command,
        [switch] $Multiline
    )
    # CMD trick to suppress and show error output because some commands write to stderr (for example, "python --version")
    [string[]]$output = & $env:comspec /c "$Command 2>&1"
    $exitCode = $LASTEXITCODE

    return @{
        Output = If ($Multiline -eq $true) { $output } else { [string]$output }
        ExitCode = $exitCode
    }
}

function ShouldReturnZeroExitCode {
    Param(
        [string] $ActualValue,
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
