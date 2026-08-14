param(
    [switch]$NoBrowser,
    [switch]$ResetDatabase
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $projectRoot '.env'
$envExample = Join-Path $projectRoot '.env.example'
$dumpFile = Join-Path $projectRoot 'database\abc_foodmart_final.dump'

Push-Location $projectRoot
try {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker is not installed or is not available in PATH.'
    }

    if (-not (Test-Path $envFile)) {
        Copy-Item $envExample $envFile
        Write-Host 'Created .env from .env.example.' -ForegroundColor Yellow
        Write-Host 'Edit .env, replace POSTGRES_PASSWORD, and run this script again.' -ForegroundColor Yellow
        exit 1
    }

    if (-not (Test-Path $dumpFile)) {
        throw "Missing database dump: $dumpFile"
    }

    $metabasePort = '3000'
    $portLine = Get-Content $envFile | Where-Object { $_ -match '^METABASE_PORT=' } | Select-Object -Last 1
    if ($portLine) {
        $metabasePort = ($portLine -split '=', 2)[1].Trim()
    }

    docker compose --env-file .env up -d postgres
    if ($LASTEXITCODE -ne 0) { throw 'Could not start PostgreSQL.' }

    Write-Host 'Waiting for PostgreSQL...'
    $ready = $false
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        docker compose --env-file .env exec -T postgres sh -lc 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' *> $null
        if ($LASTEXITCODE -eq 0) {
            $ready = $true
            break
        }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw 'PostgreSQL did not become ready.' }

    $schemaExists = docker compose --env-file .env exec -T postgres sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT to_regclass('"'"'abc_foodmart.stores'"'"') IS NOT NULL;"'
    $needsRestore = $ResetDatabase -or (($schemaExists | Out-String).Trim() -ne 't')

    if ($needsRestore) {
        if ($ResetDatabase) {
            Write-Host 'ResetDatabase was selected. Existing ABC Foodmart objects will be replaced.' -ForegroundColor Yellow
        }
        $postgresContainer = (docker compose --env-file .env ps -q postgres).Trim()
        if (-not $postgresContainer) { throw 'Could not resolve the PostgreSQL container.' }

        docker cp $dumpFile "${postgresContainer}:/tmp/abc_foodmart_final.dump" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Could not copy the database dump into PostgreSQL.' }

        docker compose --env-file .env exec -T postgres sh -lc 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --no-privileges /tmp/abc_foodmart_final.dump'
        if ($LASTEXITCODE -ne 0) { throw 'Database restore failed.' }
        Write-Host 'ABC Foodmart database restored.' -ForegroundColor Green
    }
    else {
        Write-Host 'ABC Foodmart database already exists; restore skipped.'
    }

    docker compose --env-file .env up -d metabase
    if ($LASTEXITCODE -ne 0) { throw 'Could not start Metabase.' }

    Write-Host 'Waiting for Metabase...'
    $metabaseReady = $false
    $healthUrl = "http://localhost:$metabasePort/api/health"
    for ($attempt = 1; $attempt -le 60; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 5
            if ($response.status -eq 'ok') {
                $metabaseReady = $true
                break
            }
        }
        catch {
            # Metabase is still starting.
        }
        Start-Sleep -Seconds 2
    }
    if (-not $metabaseReady) {
        throw 'Metabase did not become ready. Run: docker compose logs --tail=100 metabase'
    }

    $metabaseUrl = "http://localhost:$metabasePort"
    Write-Host "Metabase is ready: $metabaseUrl" -ForegroundColor Green
    Write-Host 'PostgreSQL host inside Metabase: postgres'
    Write-Host 'PostgreSQL database: abc_foodmart_final'
    Write-Host 'Schema to use: abc_foodmart'

    if (-not $NoBrowser) {
        Start-Process $metabaseUrl
    }
}
finally {
    Pop-Location
}
