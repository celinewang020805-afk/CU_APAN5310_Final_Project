$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location $projectRoot
try {
    docker compose --env-file .env down
    if ($LASTEXITCODE -ne 0) { throw 'Could not stop the local services.' }
    Write-Host 'Local services stopped. Database volumes were preserved.' -ForegroundColor Green
}
finally {
    Pop-Location
}
