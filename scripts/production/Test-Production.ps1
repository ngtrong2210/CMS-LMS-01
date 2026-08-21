[CmdletBinding()]
param(
    [string]$FrontendUrl = "https://lms.newletter.id.vn",
    [string]$BackendUrl = "https://app02ngtronggm-001-site1.ltempurl.com"
)

$ErrorActionPreference = "Stop"

function Assert-HttpOk([string]$Url) {
    $response = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "HTTP $($response.StatusCode): $Url"
    }
    Write-Host "HTTP_OK $($response.StatusCode): $Url"
    return $response
}

$frontend = Assert-HttpOk "$FrontendUrl/"
$health = Assert-HttpOk "$BackendUrl/health"
$healthData = $health.Content | ConvertFrom-Json
if ($healthData.status -ne "Healthy" -or $healthData.sqlServer -ne "Healthy") {
    throw "Backend hoặc SQL health chưa Healthy."
}

foreach ($route in @("/login", "/cms/dashboard", "/lms/courses")) {
    $routeResponse = Assert-HttpOk "$FrontendUrl$route"
    if ($routeResponse.Content -notmatch '<div id="app">') {
        throw "SPA rewrite không hợp lệ tại $route"
    }
}

Write-Host "PRODUCTION_SMOKE_PUBLIC_OK"
