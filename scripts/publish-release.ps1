param(
    [string]$Tag = 'v1.7.0',
    [string]$GameExe = 'build/windows/KhryuSHA2026-v8.exe',
    [string]$Repository = 'storkych/SHA2026-XruSHA',
    [switch]$PackageOnly
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ($Tag -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$') {
    throw 'Use a version tag such as v1.7.0.'
}
$sourceExe = Join-Path $projectRoot $GameExe
if (-not (Test-Path -LiteralPath $sourceExe -PathType Leaf)) { throw "Build missing: $sourceExe" }
$releaseDirectory = Join-Path $projectRoot "dist/releases/$Tag"
$portableDirectory = Join-Path $releaseDirectory 'portable'
New-Item -ItemType Directory -Path $portableDirectory -Force | Out-Null
$exeAsset = Join-Path $releaseDirectory 'KhryuSHA2026-Windows.exe'
$zipAsset = Join-Path $releaseDirectory 'KhryuSHA2026-Windows.zip'
$checksums = Join-Path $releaseDirectory 'SHA256SUMS.txt'
Copy-Item -LiteralPath $sourceExe -Destination $exeAsset -Force
Copy-Item -LiteralPath $sourceExe -Destination (Join-Path $portableDirectory 'KhryuSHA2026.exe') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/КАК ИГРАТЬ.txt') -Destination $portableDirectory -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses') -Destination $portableDirectory -Recurse -Force
$portableItems = Get-ChildItem -LiteralPath $portableDirectory | Select-Object -ExpandProperty FullName
Compress-Archive -LiteralPath $portableItems -DestinationPath $zipAsset -CompressionLevel Optimal -Force
$checksumLines = foreach ($asset in @($exeAsset, $zipAsset)) {
    '{0}  {1}' -f (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant(), [IO.Path]::GetFileName($asset)
}
$checksumLines | Set-Content -LiteralPath $checksums -Encoding ascii
Write-Output "Prepared: $releaseDirectory"
if ($PackageOnly) { return }
Push-Location $projectRoot
try {
    $changes = git status --porcelain
    if ($LASTEXITCODE -ne 0 -or $changes) { throw 'Commit and push source changes before publishing.' }
    $commit = git rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read source commit.' }
    $remoteCommit = git ls-remote origin refs/heads/main
    if ($LASTEXITCODE -ne 0 -or ($remoteCommit -split '\s+')[0] -ne $commit) { throw 'Push the current source commit to main first.' }
    gh release view $Tag --repo $Repository *> $null
    if ($LASTEXITCODE -eq 0) { throw "Release already exists: $Tag. Use a new version." }
    gh release create $Tag $exeAsset $zipAsset $checksums --repo $Repository --target $commit --draft --title "ХрюША2026 · $Tag" --notes-file (Join-Path $projectRoot 'RELEASE_NOTES.md')
    if ($LASTEXITCODE -ne 0) { throw 'Release upload failed; no release was published.' }
    $uploaded = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $releaseJson = gh api "repos/$Repository/releases/tags/$Tag"
        if ($LASTEXITCODE -eq 0) {
            $uploaded = $releaseJson | ConvertFrom-Json
            break
        }
        if ($attempt -lt 3) { Start-Sleep -Seconds 2 }
    }
    if (-not $uploaded) { throw 'Cannot inspect draft release; it remains unpublished.' }
    foreach ($asset in @($exeAsset, $zipAsset, $checksums)) {
        $localFile = Get-Item -LiteralPath $asset
        $expectedDigest = 'sha256:' + (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant()
        $match = @($uploaded.assets | Where-Object { $_.name -eq $localFile.Name -and $_.size -eq $localFile.Length -and $_.state -eq 'uploaded' -and $_.digest -eq $expectedDigest })
        if ($match.Count -ne 1) { throw "Upload verification failed for $($localFile.Name); release remains draft." }
    }
    gh api --method PATCH "repos/$Repository/releases/$($uploaded.id)" -F draft=false -f make_latest=true --jq .html_url
    if ($LASTEXITCODE -ne 0) { throw 'Assets uploaded, but publishing failed; release remains draft.' }
} finally {
    Pop-Location
}
