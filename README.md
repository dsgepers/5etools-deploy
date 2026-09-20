# 5e.tools Docker Compose Project

This project serves the 5etools source repository and the image repository from a persistent Docker volume.

## Run it

1. Copy the example environment file and fill in your Cloudflare tunnel token:

```bash
cp .env.example .env
```

2. Set the real token in `.env`:

```bash
CLOUDFLARED_TOKEN=your_cloudflare_tunnel_token_here
```

3. Start the stack:

```bash
docker compose up --build -d
```

Then open:

- http://localhost:8080
- http://localhost:8080/img/
- https://5etools.schepe.rs

## What it does

- Creates a Docker volume named `5etools_data`
- Clones the main source repo into `/data/5etools-src` on first start
- Clones the image repo into `/data/5etools-img` on first start
- Symlinks `/data/5etools-src/img` to `/data/5etools-img` so the image repo is available under `/img` in the web root
- Pulls the latest changes from both repos on every subsequent start or restart
- Serves the repository contents with nginx on port 8080
- Connects to Cloudflare Zero Trust via a tunnel for `https://5etools.schepe.rs`

## Cloudflare config

In Cloudflare Zero Trust, create a tunnel and then set a public hostname:

- Domain: `5etools.schepe.rs`
- Service: `http://web:80`

The tunnel token must be stored in `.env` as `CLOUDFLARED_TOKEN`.

## Re-sync later

```bash
docker compose up -d --force-recreate
```

This will re-run the entrypoint, fetch, and pull the latest repo contents before nginx starts.
