[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$solutionPath = Join-Path $projectRoot "Sims.sln"
$apiProject = Join-Path $projectRoot "src\Sims.Api\Sims.Api.csproj"
$outputPath = Join-Path $projectRoot "artifacts\production\backend"
$zipPath = Join-Path $projectRoot "artifacts\production\backend-production.zip"

dotnet restore $solutionPath
dotnet build $solutionPath -c Release --no-restore
dotnet publish $apiProject -c Release --no-build -o $outputPath

$publishedMedia = Join-Path $outputPath "wwwroot\Media"
if (Test-Path -LiteralPath $publishedMedia) {
    throw "Package backend chứa wwwroot/Media. Dừng deploy để bảo vệ dữ liệu production."
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $outputPath "*") -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "BACKEND_PUBLISH_OK: $outputPath"
Write-Host "BACKEND_PACKAGE_OK: $zipPath"
