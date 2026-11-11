$ErrorActionPreference = "Stop"

$intermediates = Join-Path $PSScriptRoot "..\android\app\build\intermediates"
if (-not (Test-Path $intermediates)) {
    throw "Release build intermediates not found. Run flutter build apk --release first."
}

$manifests = Get-ChildItem -Path $intermediates -Filter AndroidManifest.xml -File -Recurse |
    Where-Object {
        $_.FullName -match '[\\/]merged_manifests[\\/]release[\\/]' -or
        $_.FullName -match '[\\/]merged_manifest[\\/]release[\\/]' -or
        $_.FullName -match '[\\/]packaged_manifests[\\/]release[\\/]'
    }

if (-not $manifests) {
    throw "Merged release manifest not found under $intermediates. Run flutter build apk --release first."
}

foreach ($manifest in $manifests) {
    [xml]$xml = Get-Content -Path $manifest.FullName -Raw
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $namespaceManager.AddNamespace("android", "http://schemas.android.com/apk/res/android")
    $internetPermission = $xml.SelectNodes(
        "/manifest/*[starts-with(local-name(), 'uses-permission') and @android:name='android.permission.INTERNET']",
        $namespaceManager
    )
    if ($internetPermission.Count -gt 0) {
        throw "Release manifest contains android.permission.INTERNET: $($manifest.FullName)"
    }
}

Write-Output "Verified: no merged release manifest declares android.permission.INTERNET."
