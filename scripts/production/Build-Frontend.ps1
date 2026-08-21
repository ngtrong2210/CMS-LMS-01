[CmdletBinding()]
param(
    [string]$ApiUrl = "https://app02ngtronggm-001-site1.ltempurl.com/api"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$frontendPath = Join-Path $projectRoot "frontend"

Push-Location $frontendPath
try {
    if (-not (Test-Path -LiteralPath "package-lock.json")) {
        throw "Không tìm thấy frontend/package-lock.json."
    }

    $env:VITE_API_URL = $ApiUrl
    $env:VITE_DATA_MODE = "api"
    npm ci
    npm run build

    $indexPath = Join-Path $frontendPath "dist\index.html"
    if (-not (Test-Path -LiteralPath $indexPath)) {
        throw "Frontend build không tạo dist/index.html."
    }

    Write-Host "FRONTEND_BUILD_OK: $indexPath"
}
finally {
    Pop-Location
}
