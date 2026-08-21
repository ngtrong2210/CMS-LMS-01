[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$frontendPath = Join-Path $projectRoot "frontend"
$vercelProjectPath = Join-Path $frontendPath ".vercel\project.json"

if (-not (Test-Path -LiteralPath $vercelProjectPath)) {
    throw "Frontend chưa được link Vercel."
}

$vercelProject = Get-Content -LiteralPath $vercelProjectPath -Raw | ConvertFrom-Json
if ($vercelProject.projectName -ne "cms-vue-vercel") {
    throw "Sai Vercel project: $($vercelProject.projectName)"
}

Push-Location $frontendPath
try {
    npx vercel --prod --yes
    if ($LASTEXITCODE -ne 0) { throw "Vercel production deploy thất bại." }
}
finally {
    Pop-Location
}

Write-Host "VERCEL_PRODUCTION_DEPLOY_OK"
