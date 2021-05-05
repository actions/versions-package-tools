using module "./base-parser.psm1"

class XamarinVersionsParser: BaseVersionsParser {
    [PSCustomObject] GetAvailableVersions() {
        $allVersions = $this.ParseAllAvailableVersions()
        return $allVersions
    }

    [hashtable] GetUploadedVersions() {
        $url = $this.BuildGitHubFileUrl("actions", "virtual-environments", "main", "images/macos/toolsets/toolset-11.0.json")
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        $xamarin = $releases.xamarin
        $xamarinReleases = @{
            'Mono Framework' = $xamarin.'mono-versions'
            'Xamarin.Android' = $xamarin.'android-versions'
            'Xamarin.iOS' = $xamarin.'ios-versions'
            'Xamarin.Mac' = $xamarin.'mac-versions'
        }
        return $xamarinReleases
    }

    hidden [PSCustomObject] ParseAllAvailableVersions() {
        $url = "http://aka.ms/manifest/stable"
        $filteredProducts = @('Mono Framework', 'Xamarin.Android', 'Xamarin.iOS', 'Xamarin.Mac')
        $releases = Invoke-RestMethod $url -MaximumRetryCount $this.ApiRetryCount -RetryIntervalSec $this.ApiRetryIntervalSeconds
        $items = $releases.items
        $products = $items | Where-Object {$_.name -in $filteredProducts} | Sort-Object name | Select-Object name, version
        return $products
    }
}