param (
    [string] $ToolName
)

$targetPath = $env:AGENT_TOOLSDIRECTORY
if ([string]::IsNullOrEmpty($targetPath)) {
    # GitHub Windows images don't have `AGENT_TOOLSDIRECTORY` variable
    $targetPath = $env:RUNNER_TOOL_CACHE
}

if ($ToolName) {
    $targetPath = Join-Path $targetPath $ToolName
}

if (Test-Path $targetPath) {
    Get-ChildItem -Path $targetPath -Recurse | Where-Object { $_.LinkType -eq "SymbolicLink" } | ForEach-Object { $_.Delete() }
    Remove-Item -Path $targetPath -Recurse -Force
}
