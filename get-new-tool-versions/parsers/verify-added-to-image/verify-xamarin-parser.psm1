function Search-XamarinVersionsNotOnImage {
    param (
        [string]$ReleasesUrl,
        [array]$FilterProducts
    )

    $xamarinReleases = (Invoke-RestMethod $ReleasesUrl).items
    $filteredReleases = $xamarinReleases | Where-Object {$_.name -in $FilterProducts.name} | Sort-Object name | Select-Object name, version
    $toolsetUrl = "https://raw.githubusercontent.com/actions/runner-images/main/images/macos/toolsets/toolset-12.json"
    $uploadedReleases = (Invoke-RestMethod $toolsetUrl).xamarin
    $releasesOnImage = @()
    foreach ($FilterProduct in $FilterProducts) {
        $releasesOnImage += @{$FilterProduct.name = $uploadedReleases.($FilterProduct.property)}
    }
    $versionsToAdd = $filteredReleases | Where-Object {$releasesOnImage.($_.name) -notcontains $_.version} | ForEach-Object {[string]::Empty} {
        '{0,-15} : {1}' -f $_.name, $_.version
    }
    return $versionsToAdd
}
