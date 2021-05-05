using module "./node-parser.psm1"
using module "./go-parser.psm1"
using module "./python-parser.psm1"
using module "./xamarin-parser.psm1"

function Get-ToolVersionsParser {
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )

    switch ($ToolName) {
        "Node" { return [NodeVersionsParser]::New() }
        "Go" { return [GoVersionsParser]::New() }
        "Python" { return [PythonVersionsParser]::New() }
        "Xamarin" { return [XamarinversionsParser]::New() }
        Default {
            throw "Unknown tool name"
        }
    }
}