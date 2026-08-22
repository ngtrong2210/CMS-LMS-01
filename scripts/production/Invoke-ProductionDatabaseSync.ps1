[CmdletBinding()]
param(
    [string]$ConfigurationPath = "src\Sims.Api\appsettings.Production.json"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$configurationFile = Join-Path $projectRoot $ConfigurationPath
$migrationFile = Join-Path $projectRoot "database\production\PRODUCTION_SYNC_20260821.sql"
$artifactPath = Join-Path $projectRoot "artifacts\production\sql"
$preAuditPath = Join-Path $artifactPath "pre-deploy-audit.json"
$postAuditPath = Join-Path $artifactPath "post-deploy-audit.json"

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw "Không tìm thấy sqlcmd."
}
if (-not (Test-Path -LiteralPath $configurationFile)) {
    throw "Không tìm thấy cấu hình production cục bộ: $configurationFile"
}

$configuration = Get-Content -LiteralPath $configurationFile -Raw | ConvertFrom-Json
$connection = New-Object System.Data.SqlClient.SqlConnectionStringBuilder $configuration.ConnectionStrings.DefaultConnection
New-Item -ItemType Directory -Path $artifactPath -Force | Out-Null

function Get-DatabaseAudit {
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connection.ConnectionString
    try {
        $sqlConnection.Open()

        $summaryCommand = $sqlConnection.CreateCommand()
        $summaryCommand.CommandText = @"
Select
    Getutcdate() As AuditUtc,
    Db_name() As DatabaseName,
    @@Servername As ServerName,
    (Select Count(*) From sys.tables Where schema_id = Schema_id(N'dbo')) As TableCount,
    (Select Count(*) From sys.procedures Where schema_id = Schema_id(N'dbo')) As ProcedureCount;
"@
        $summaryReader = $summaryCommand.ExecuteReader()
        if (-not $summaryReader.Read()) { throw "Không đọc được thông tin tổng quan database." }
        $audit = [ordered]@{
            AuditUtc = $summaryReader.GetDateTime(0).ToString("o")
            DatabaseName = $summaryReader.GetString(1)
            ServerName = $summaryReader.GetString(2)
            TableCount = $summaryReader.GetInt32(3)
            ProcedureCount = $summaryReader.GetInt32(4)
            Tables = @()
        }
        $summaryReader.Close()

        $tableCommand = $sqlConnection.CreateCommand()
        $tableCommand.CommandText = @"
Select
    t.name As TableName,
    Sum(p.rows) As RecordCount
From sys.tables t
    Inner Join sys.partitions p On p.object_id = t.object_id And p.index_id In (0, 1)
Where t.schema_id = Schema_id(N'dbo')
Group By t.name
Order By t.name;
"@
        $tableReader = $tableCommand.ExecuteReader()
        while ($tableReader.Read()) {
            $audit.Tables += [ordered]@{
                TableName = $tableReader.GetString(0)
                RecordCount = $tableReader.GetInt64(1)
            }
        }
        $tableReader.Close()
        return $audit
    }
    finally {
        $sqlConnection.Dispose()
    }
}

function Write-DatabaseAudit([object]$Audit, [string]$Path) {
    $Audit | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Assert-NoRecordCountDecrease([object]$Before, [object]$After) {
    $afterByTable = @{}
    foreach ($table in $After.Tables) { $afterByTable[$table.TableName] = [long]$table.RecordCount }

    $decreases = @()
    foreach ($table in $Before.Tables) {
        if ($afterByTable.ContainsKey($table.TableName) -and $afterByTable[$table.TableName] -lt [long]$table.RecordCount) {
            $decreases += "$($table.TableName): $($table.RecordCount) -> $($afterByTable[$table.TableName])"
        }
    }
    if ($decreases.Count -gt 0) {
        throw "Phát hiện số dòng giảm sau migration: $($decreases -join '; ')"
    }
}

Push-Location $projectRoot
try {
    $preAudit = Get-DatabaseAudit
    Write-DatabaseAudit $preAudit $preAuditPath

    & sqlcmd -S $connection.DataSource -d $connection.InitialCatalog -U $connection.UserID -P $connection.Password -C -b -V 16 -f 65001 -i $migrationFile
    if ($LASTEXITCODE -ne 0) { throw "Production migration thất bại." }

    $postAudit = Get-DatabaseAudit
    Write-DatabaseAudit $postAudit $postAuditPath
    Assert-NoRecordCountDecrease $preAudit $postAudit
}
finally {
    Pop-Location
}

Write-Host "PRODUCTION_DATABASE_SYNC_OK"
Write-Host "PRE_DEPLOY_AUDIT: $preAuditPath"
Write-Host "POST_DEPLOY_AUDIT: $postAuditPath"
Write-Host "ROW_COUNT_DECREASES: 0"
