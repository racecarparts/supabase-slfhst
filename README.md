# supabase-slfhst

Self-hosted Supabase stack for Portainer. One repo, many instances.

## How it works

Portainer's **Git Stack** feature clones this repo to a temp path on the host and runs `docker compose` from that directory. Relative volume paths like `./volumes/api/kong.yml` work correctly — no manual cloning needed.

Each instance gets its own `.env.*` file with unique secrets and ports. You generate it locally with `generate-env.sh`, then upload it in the Portainer UI when creating the stack.

## Spinning up a new instance

### 1. Generate an env file

```bash
./generate-env.sh <instance-name>
# e.g. ./generate-env.sh homelab
```

This generates all secrets and auto-assigns ports (tracked in `.ports`). Both files are gitignored — never commit them.

Edit the URLs in the generated file before deploying:
- `SUPABASE_PUBLIC_URL` / `API_EXTERNAL_URL` — your host IP or domain
- `SITE_URL` — your app's URL
- `SMTP_*` — only needed for email auth (password reset, invites)

### 2. Create a Portainer stack

1. Portainer → **Stacks** → **Add stack**
2. Select **Git repository**
3. Repository URL: your fork of this repo
4. Compose path: `docker-compose.yml`
5. **Environment variables** → **Load variables from .env file** → upload your `.env.<instance-name>`
6. Name the stack to match your instance (e.g. `supabase-homelab`) — this becomes the Docker project name and keeps containers isolated
7. Deploy

### 3. Access Studio

```
http://<host>:<KONG_HTTP_PORT>
```

Login with `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` from your env file (printed at end of `generate-env.sh`).

## Multiple instances on the same host

`generate-env.sh` handles this automatically. Each instance gets a port slot:

```
Slot 0: Kong=8000, HTTPS=8443, Postgres=5432, Pooler=6543
Slot 1: Kong=8001, HTTPS=8444, Postgres=5433, Pooler=6544
...
```

Port assignments are stored in `.ports` (gitignored). Just run the script for each instance — no manual port tracking needed.

Give each stack a unique name in Portainer. Docker namespaces all containers under the stack name, so there are no container name conflicts.

## Upgrading

Update image tags in `docker-compose.yml`, commit and push, then in Portainer: **Stacks** → your stack → **Pull and redeploy**.

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
