# supabase-slfhst

Self-hosted Supabase stack. One repo, many instances.

## Spinning up a new instance

### 1. Clone and generate an env file

```bash
git clone <repo-url> supabase-<instance-name>
cd supabase-<instance-name>
./generate-env.sh <instance-name>
# e.g. ./generate-env.sh homelab
```

This generates all secrets and auto-assigns ports (tracked in `.ports`). Both files are gitignored — never commit them.

Edit the URLs in the generated file before deploying:
- `SUPABASE_PUBLIC_URL` / `API_EXTERNAL_URL` — your host IP or domain
- `SITE_URL` — your app's URL
- `SMTP_*` — only needed for email auth (password reset, invites)

### 2. Start

```bash
docker compose --env-file .env.<instance-name> up -d
```

### 3. Access Studio

```
http://<host>:<KONG_HTTP_PORT>
```

Login with `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` from your env file (printed at end of `generate-env.sh`).

### Stop / destroy

```bash
docker compose --env-file .env.<instance-name> down -v
```

## Multiple instances on the same host

Clone the repo into a separate directory per instance. `generate-env.sh` handles port assignment automatically:

```
Slot 0: Kong=8000, HTTPS=8443, Postgres=5432, Pooler=6543
Slot 1: Kong=8001, HTTPS=8444, Postgres=5433, Pooler=6544
...
```

Port assignments are stored in `.ports` (gitignored). Just run the script for each instance — no manual port tracking needed.

Each clone is its own Docker project, so containers are fully isolated by name.

## Upgrading

Update image tags in `docker-compose.yml`, pull the latest repo changes, then redeploy:

```bash
git pull
docker compose --env-file .env.<instance-name> up -d --pull always
```

## Using Portainer

If deploying via Portainer, the host running the Portainer agent must have the repo cloned locally. Portainer's remote agent architecture does not transfer repo files to the agent host — bind mounts will fail if Portainer server and agent are on different machines.

On the agent host: clone the repo, generate the env file, then in Portainer create a stack pointing to the local `docker-compose.yml` and upload the `.env.<instance-name>` file.

## Repo structure

```
docker-compose.yml          # All services (no hardcoded secrets or ports)
.env.example                # Reference — all variables documented with descriptions
generate-env.sh             # Generates .env.<name> with secrets + auto-assigned ports
volumes/
  api/
    kong.yml                # Kong API gateway routing rules
    kong-entrypoint.sh      # Env var substitution + Kong startup
  db/
    *.sql                   # Postgres init scripts (run once on first boot)
    data/                   # Postgres data — gitignored, managed by Docker
  functions/
    main/index.ts           # Edge runtime entrypoint
  logs/
    vector.yml              # Vector log routing config
  pooler/
    pooler.exs              # Supavisor tenant init
  storage/                  # File storage — gitignored, managed by Docker
  snippets/                 # Studio snippets — gitignored, managed by Docker
```

## What's gitignored

- `.env.*` — instance env files with secrets
- `.ports` — port slot registry
- `volumes/db/data/` — Postgres data
- `volumes/storage/` — uploaded files
- `volumes/snippets/` — Studio snippets
