#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or is not available in PATH." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example. Replace POSTGRES_PASSWORD and run again." >&2
  exit 1
fi

if [[ ! -f database/abc_foodmart_final.dump ]]; then
  echo "Missing database/abc_foodmart_final.dump" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

docker compose --env-file .env up -d postgres

echo "Waiting for PostgreSQL..."
for attempt in $(seq 1 30); do
  if docker compose --env-file .env exec -T postgres \
    sh -lc 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" -eq 30 ]]; then
    echo "PostgreSQL did not become ready." >&2
    exit 1
  fi
  sleep 2
done

schema_exists="$(docker compose --env-file .env exec -T postgres \
  sh -lc 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT to_regclass('"'"'abc_foodmart.stores'"'"') IS NOT NULL;"' | tr -d '[:space:]')"

if [[ "$schema_exists" != "t" ]]; then
  container_id="$(docker compose --env-file .env ps -q postgres)"
  docker cp database/abc_foodmart_final.dump "${container_id}:/tmp/abc_foodmart_final.dump"
  docker compose --env-file .env exec -T postgres \
    sh -lc 'pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists --no-owner --no-privileges /tmp/abc_foodmart_final.dump'
  echo "ABC Foodmart database restored."
else
  echo "ABC Foodmart database already exists; restore skipped."
fi

docker compose --env-file .env up -d metabase

echo "Waiting for Metabase..."
for attempt in $(seq 1 60); do
  if curl -fsS "http://localhost:${METABASE_PORT:-3000}/api/health" >/dev/null 2>&1; then
    echo "Metabase is ready at http://localhost:${METABASE_PORT:-3000}"
    exit 0
  fi
  if [[ "$attempt" -eq 60 ]]; then
    echo "Metabase did not become ready. Run: docker compose logs --tail=100 metabase" >&2
    exit 1
  fi
  sleep 2
done
