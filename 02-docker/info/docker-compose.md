# Docker Compose workflow (Week 03)
## What Compose adds
Docker Compose manages multi-container applications from a single YAML file. Instead of running separate `docker run` commands and manually wiring networks/volumes, a `docker-compose.yml` declares all services, their dependencies, networking, volumes, and health checks in one place.

## Stack overview
The `02-docker/app/docker-compose.yml` defines two services:

| Service | Image | Purpose |
| ------- | ----- | ------- |
| `app` | Built from local `Dockerfile` | FastAPI app — visit counter backed by Redis |
| `redis` | `redis:7-alpine` | In-memory cache storing the visit count |

The app writes visit timestamps to a file volume (`app_data:/data`) **and** increments a counter in Redis. The `/health` endpoint reports both app and Redis status.

## Commands
All commands run from `02-docker/app/` (the directory containing `docker-compose.yml`).

### Start the stack
```bash
docker compose up -d
# up: create and start all services
# -d: detached mode (runs in background)
```

### Rebuild after code or Dockerfile changes
```bash
docker compose up -d --build
# --build: force image rebuild before starting
```

### View logs
```bash
docker compose logs            # show combined log history for all services
docker compose logs app        # show logs for the app service only
docker compose logs -f         # -f: follow/stream logs in real time (Ctrl-C to stop)
```

### Check service status
```bash
docker compose ps
# shows running containers, ports, health status
```

### Stop and remove everything
```bash
docker compose down
# stops containers and removes the default network
# named volumes (app_data, redis_data) are preserved

docker compose down -v
# -v: also remove named volumes (deletes all persisted data)
```

### Run a one-off command in a service
```bash
docker compose exec app sh
# exec: run a command in a running container
# app: service name
# sh: the command to run (opens a shell)

docker compose exec redis redis-cli ping
# quick check — should return PONG
```

## Service dependencies and startup order
```yaml
depends_on:
  redis:
    condition: service_healthy
```

`depends_on` with `condition: service_healthy` means Compose waits for the Redis healthcheck to pass before starting the app container. Without the `condition` key, Compose only waits for the container to _start_ (not for the process inside to be ready).

## Healthchecks
Healthchecks let Compose (and Docker) know whether a service is actually working, not just running.

### Redis healthcheck
```yaml
healthcheck:
  test: ["CMD", "redis-cli", "ping"]
  interval: 10s
  timeout: 3s
  retries: 3
  start_period: 3s
```

- `test`: the command Docker runs inside the container. `redis-cli ping` returns `PONG` when Redis is ready.
- `interval`: time between checks.
- `timeout`: max time to wait for a single check before marking it failed.
- `retries`: consecutive failures needed to mark the container as `unhealthy`.
- `start_period`: grace period after container start during which failed checks don't count toward retries (gives the process time to initialize).

### App healthcheck
```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 5s
```

Uses Python's built-in `urllib` (already in the image) to hit the `/health` endpoint. A non-200 response raises an exception and Docker counts it as a failed check.

## Restart policies
```yaml
restart: unless-stopped
```

| Policy | Behavior |
| ------ | -------- |
| `no` | Never restart (default). |
| `on-failure` | Restart only on non-zero exit code. |
| `always` | Restart unconditionally, including after Docker daemon restart. |
| `unless-stopped` | Like `always`, but does **not** restart if the container was manually stopped before the daemon restarted. |

`unless-stopped` is a safe default for lab services: containers come back after a reboot or crash but stay down when intentionally stopped.

## Volumes
```yaml
volumes:
  app_data:
  redis_data:
```

Named volumes are declared at the top level and mounted into services. Data survives `docker compose down` (unless `-v` is passed). To inspect a volume:

```bash
docker volume inspect 02-docker-app_app_data
# name prefix comes from the project name (directory name by default)
```

## Networking
Compose creates a default bridge network for the stack. Services reference each other by service name (`redis`, `app`). No manual `docker network create` needed.

```bash
docker compose exec app sh -c "ping -c 2 redis"
# verifies DNS resolution between containers on the Compose network
```

---

## Debugging common Compose failures
### 1. Port already in use
**Symptom:** `Error starting userland proxy: listen tcp4 0.0.0.0:8000: bind: address already in use`

**Fix:**

```bash
lsof -i :8000
# find the PID using the port

kill <PID>
# or change the host port mapping in docker-compose.yml (e.g. "8001:8000")
```

### 2. Container exits immediately (exit code 1 or 137)
**Symptom:** `docker compose ps` shows `Exited (1)` or `Exited (137)`.

**Debug:**

```bash
docker compose logs app
# check the last few lines for the actual error (import error, missing env var, crash)

docker compose run --rm app sh
# start a throwaway container with a shell to inspect the environment
```

- Exit code **1**: application error (bad config, missing dependency, uncaught exception).
- Exit code **137**: container killed by OOM or `docker kill` (check Docker memory limits).

### 3. Service cannot connect to another service
**Symptom:** `ConnectionRefusedError` or `Could not resolve host` when the app tries to reach Redis.

**Checklist:**

1. Is the dependency running? `docker compose ps` — look for `Up (healthy)`.
2. Is the hostname correct? The hostname must match the **service name** in `docker-compose.yml` (e.g. `redis`, not `localhost` or the container name).
3. Is the port correct? Services on the Compose network use the **container port** (6379), not the host-mapped port.
4. Is the dependency healthy? If using `depends_on: condition: service_healthy`, check `docker compose logs redis` for startup errors.

### 4. Changes not showing after rebuild
**Symptom:** Code changes don't appear even after `docker compose up -d`.

**Fix:**

```bash
docker compose up -d --build
# --build forces a fresh image build; without it, Compose reuses the cached image
```

If the issue persists, clear the build cache:

```bash
docker compose build --no-cache
docker compose up -d
```

### 5. Volume data is stale or missing
**Symptom:** Expected data not present, or old data persists after code changes.

**Debug:**

```bash
docker volume ls
# list volumes — check if the expected volume exists

docker compose down -v
docker compose up -d --build
# nuclear option: remove volumes and rebuild from scratch
```

### 6. Healthcheck stuck on "starting"
**Symptom:** `docker compose ps` shows `(health: starting)` indefinitely.

**Debug:**

```bash
docker inspect --format='{{json .State.Health}}' fp-hello-api | python3 -m json.tool
# shows healthcheck log with exit codes and output from each probe
```

Common causes:

- The test command is wrong (typo, binary not in PATH).
- `start_period` is too short and the app needs more time.
- The healthcheck endpoint itself is broken.
