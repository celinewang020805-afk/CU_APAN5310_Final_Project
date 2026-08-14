# Metabase Local Setup

The Docker stack intentionally starts with a clean Metabase application database. A private Metabase H2 backup is not committed because it contains user accounts, connection credentials, and application settings.

## First-time setup

1. Run `scripts/start.ps1` on Windows or `scripts/start.sh` on macOS/Linux.
2. Open `http://localhost:3000`.
3. Create a local Metabase administrator account.
4. Add a PostgreSQL database with these values:

| Setting | Value |
|---|---|
| Display name | `ABC Foodmart` |
| Host | `postgres` |
| Port | `5432` |
| Database name | `abc_foodmart_final` |
| Username | `postgres` |
| Password | The value in `.env` |
| Schemas | `abc_foodmart` |
| SSL | Off |
| SSH tunnel | Off |

`postgres` is the Docker service name. Do not use `localhost` as the database host inside Metabase.

## Build the dashboard

Create a dashboard named **ABC Foodmart Store Manager Dashboard** with these tabs:

1. Store Overview
2. Sales & Products
3. Workforce & Attendance
4. Inventory & Receiving
5. Operating Expenses

Add three dashboard filters:

- Start Date
- End Date
- Store

The SQL files in `queries/` use Metabase optional-clause syntax. Configure `store_name` as a field filter mapped to `abc_foodmart.stores.store_name`. Configure `start_date` and `end_date` as date variables.

The Workforce & Attendance page intentionally excludes the former **Actual Labor Hours by Job Role** card.

## Local addresses

- Metabase: `http://localhost:3000`
- PostgreSQL for desktop SQL tools: `localhost:5432`

Both ports are bound to `127.0.0.1`; the services are not exposed to the public network.
