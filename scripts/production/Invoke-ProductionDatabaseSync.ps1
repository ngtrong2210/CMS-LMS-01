[CmdletBinding()]
param(
    [string]$ConfigurationPath = "src\LmsCms.Api\appsettings.Production.json"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$configurationFile = Join-Path $projectRoot $ConfigurationPath
$migrationFile = Join-Path $projectRoot "database\production\PRODUCTION_SYNC_20260821.sql"
$artifactPath = Join-Path $projectRoot "artifacts\production\sql"
$auditPath = Join-Path $artifactPath "pre-deploy-audit.txt"

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw "Không tìm thấy sqlcmd."
}
if (-not (Test-Path -LiteralPath $configurationFile)) {
    throw "Không tìm thấy cấu hình production cục bộ: $configurationFile"
}

$configuration = Get-Content -LiteralPath $configurationFile -Raw | ConvertFrom-Json
$connection = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $configuration.ConnectionStrings.DefaultConnection
New-Item -ItemType Directory -Path $artifactPath -Force | Out-Null

$auditQuery = @"
Set Nocount On;
Select Getutcdate() AuditUtc, Db_name() DatabaseName, @@Servername ServerName;
Select Count(*) TableCount From sys.tables Where schema_id = Schema_id(N'dbo');
Select Count(*) ProcedureCount From sys.procedures Where schema_id = Schema_id(N'dbo');
Select t.name TableName, Sum(p.rows) RowCount
From sys.tables t
    Inner Join sys.partitions p On p.object_id = t.object_id And p.index_id In (0, 1)
Where t.schema_id = Schema_id(N'dbo')
Group By t.name
Order By t.name;
"@

Push-Location $projectRoot
try {
    & sqlcmd -S $connection.DataSource -d $connection.InitialCatalog -U $connection.UserID -P $connection.Password -C -b -V 16 -W -Q $auditQuery -o $auditPath
    if ($LASTEXITCODE -ne 0) { throw "Không thể tạo audit SQL trước deploy." }

    & sqlcmd -S $connection.DataSource -d $connection.InitialCatalog -U $connection.UserID -P $connection.Password -C -b -V 16 -f 65001 -i $migrationFile
    if ($LASTEXITCODE -ne 0) { throw "Production migration thất bại." }
}
finally {
    Pop-Location
}

Write-Host "PRODUCTION_DATABASE_SYNC_OK"
Write-Host "PRE_DEPLOY_AUDIT: $auditPath"
