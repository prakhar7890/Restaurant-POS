# Restaurant POS

Restaurant POS monorepo with a FastAPI backend, Tauri 2 Windows desktop shell,
Expo mobile shell, and shared TypeScript package. Inventory, stock, ingredient,
purchasing, and supplier features are explicitly excluded.

> **Current status:** No staging deployment has occurred. Authentication and
> permission-protected menu and order routes are mounted, and the desktop
> client has sign-in, POS cart, order placement, order history, table
> selection, a polling kitchen display, and online billing, tax-profile, and
> payment-record workflows. These APIs are permission-protected.
> Users and trusted devices must still be provisioned outside the public API.
> Offline order capture/sync, production/PostgreSQL validation, and staging
> deployment are not complete.
> This is not production- or pilot-ready.

## Prerequisites on Windows

Install Git, Node.js 22.12 or newer (Corepack is included),
[uv](https://docs.astral.sh/uv/), and PostgreSQL 16 or newer as a native
Windows service. Add PostgreSQL's `bin` directory to PowerShell's `PATH` so
`psql` is available. Docker Desktop is not required for development. Tauri
builds also need Rust, Visual Studio 2022 Build Tools with the C++ workload,
and the WebView2 Runtime. Expo Go supports device-based development; iOS
Simulator and native iOS builds require macOS and Xcode.

## Local development

Use VS Code's PowerShell terminal. Full native PostgreSQL setup, secure
connection-string configuration, and the environment checker are documented
in [Development setup](docs/development.md). Initial tools setup from the
repository root:

```powershell
corepack pnpm install
uv python install 3.12
uv sync --project backend --python 3.12
```

Run `.\scripts\Check-Development.ps1` after PostgreSQL and the API are running
to check local tool versions, PostgreSQL connectivity, and backend health.

After creating a native PostgreSQL database and setting `DATABASE_URL` in the
same terminal, apply the schema and start the backend:

```powershell
uv run --project backend python -m alembic -c backend/alembic.ini upgrade head
uv run --project backend uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Check health from another terminal. Start each client in a separate terminal:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
Invoke-RestMethod http://127.0.0.1:8000/ready
corepack pnpm dev:desktop
corepack pnpm dev:mobile
```

For an Android emulator use `http://10.0.2.2:8000`; a physical device must
use the development computer's LAN IP. Override with `EXPO_PUBLIC_API_URL` or
`VITE_API_URL` only when needed.

## Tests and checks

```powershell
uv run --project backend pytest
uv run --project backend ruff check backend
uv run --project backend ruff format --check backend
corepack pnpm test
corepack pnpm lint
corepack pnpm --filter @restaurant-pos/desktop build
corepack pnpm --filter @restaurant-pos/mobile exec tsc --noEmit
corepack pnpm format:check
```

Dockerfiles and Compose workflows remain available but are optional for native
development. See [Deployment guide](docs/deployment.md),
[Operations runbook](docs/operations.md), and [Pilot checklist](docs/pilot-checklist.md)
for container deployment, backup/recovery, and acceptance guidance.

For approval-gated Google Cloud Run source-build and Cloud SQL staging
preparation without local Docker, see
[Google Cloud staging preparation](docs/google-cloud-staging.md). No cloud
resources are created by the local setup.

## Repository layout

```text
backend/             FastAPI app, SQLAlchemy models, Alembic, and pytest tests
desktop/             Tauri 2 + React + TypeScript Windows shell
mobile/              Expo + React Native + TypeScript shell
packages/shared/     Shared TypeScript API helpers
docs/                Native setup, deployment, operations, and pilot guidance
```

## Known limitations

The API exposes liveness/readiness, login/current-user/logout, menu category
and item management, order creation/history/status, dining tables, kitchen
tickets, outlet tax profiles, bills, receipts, manual payment records, refunds,
voids, and permission-protected report/audit routes. Every feature route is
scoped to the authenticated tenant, authorized outlet, and device-bound
outlet. Dine-in order creation reserves an active table and creates a
snapshot-based KOT in the same transaction. The desktop kitchen board polls
the authorized outlet API; it does not use WebSockets. Additional-item ticket
batches are not supported because order editing is not implemented.

Tax profiles are configured per outlet and attached to menu items. Tax rates
are not preconfigured for any jurisdiction. Payment and refund entries are
explicitly manual/unverified; no payment provider is integrated. See
[Development setup](docs/development.md) for endpoints, permission names,
rounding behavior, limits, and Windows commands.

Orders and bills use server-side Decimal totals and immutable snapshots.
Payment/refund requests use idempotency keys, and bills are not overwritten
when corrected; the original records remain. The desktop access token is held
in memory; users must enter a pre-registered device UUID to sign in. There is
no public user provisioning or first-admin/device bootstrap workflow. Offline
order capture/synchronization and backup automation remain unimplemented.
The project has not been validated against PostgreSQL concurrency or
production deployment, does not provide evidence of backup restoration or
jurisdiction-specific tax compliance, and has no provider-verified payment
acceptance. Do not load real restaurant or customer data or use this release
for sales.
