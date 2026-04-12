# Docker Compose — what I learned (Week 03)
## What Docker Compose is
Docker Compose is a tool for defining and running multi-container applications from a single YAML file. Instead of running multiple `docker run` commands with long flag lists and manually creating networks and volumes, I describe the entire stack in `docker-compose.yml` and manage it with one command.

Key difference from plain Docker:

- Plain Docker: one command per container, manual network/volume wiring, manual startup ordering
- Compose: one file declares everything, one command starts/stops the whole stack

Compose is not an orchestrator like Kubernetes. It runs containers on a single host. It is a development and lab tool, not a production deployment tool (though `docker compose` in production exists for simple cases).

## The Compose file — line by line
### Services
```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
```

`services` is the top-level key. Each child (`app`, `redis`) is a service — a container definition. `build.context` is the build context path (same as `docker build .`). `build.dockerfile` specifies which Dockerfile to use. If omitted, Compose looks for `Dockerfile` in the context directory.

```yaml
    container_name: fp-hello-api
```

Assigns a fixed container name. Without this, Compose generates a name like `app-app-1` (project name + service name + instance number). Fixed names are easier to reference in logs and commands but prevent scaling the service to multiple instances.

```yaml
    ports:
      - "8000:8000"
```

Same as `docker run -p 8000:8000`. Maps host port to container port. Format: `"HOST:CONTAINER"`. Quotes are recommended to avoid YAML parsing issues with certain port formats.

```yaml
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
```

Sets environment variables inside the container. The app reads these to know where Redis is. `REDIS_HOST=redis` uses the **service name** as the hostname — Compose's internal DNS resolves `redis` to the Redis container's IP on the shared network.

```yaml
    volumes:
      - app_data:/data
```

Mounts the named volume `app_data` at `/data` inside the container. Same as `--mount type=volume,src=app_data,dst=/data`.

```yaml
    depends_on:
      redis:
        condition: service_healthy
```

Controls startup order. Without `condition`, Compose only waits for the container to **start** (the process may not be ready yet). With `condition: service_healthy`, Compose waits until the Redis healthcheck passes before starting the app. This prevents the app from crashing on startup because Redis isn't ready yet.

There are three conditions:

- `service_started` — default, just waits for the container to start
- `service_healthy` — waits for the healthcheck to pass
- `service_completed_successfully` — waits for the container to exit with code 0 (useful for init/migration containers)

### Healthchecks
```yaml
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 3s
```

Healthchecks tell Docker whether a service is actually working, not just running. Docker runs the `test` command inside the container at every `interval`. If the command exits non-zero, it counts as a failure. After `retries` consecutive failures, the container is marked `unhealthy`.

- `test`: the command to run. `CMD` form runs through the container's shell. `redis-cli ping` returns `PONG` if Redis is accepting connections.
- `interval`: how often to check (every 10 seconds).
- `timeout`: max time to wait for the check command. If it takes longer, it's a failure.
- `retries`: how many consecutive failures before marking unhealthy.
- `start_period`: grace period after container start. Failures during this window don't count toward retries. Gives the process time to initialize.

For the app, I used Python's `urllib` to hit the `/health` endpoint:

```yaml
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
```

This works because Python is already in the image. A non-200 response raises an exception, which Docker counts as a failure. I could also use `curl`, but that would require installing it in the image.

### Restart policies
```yaml
    restart: unless-stopped
```

Controls what happens when a container exits or the Docker daemon restarts.

| Policy           | What it does                                                             |
| ---------------- | ------------------------------------------------------------------------ |
| `no`             | Never restart. Default.                                                  |
| `on-failure`     | Restart only if the container exits with a non-zero code.                |
| `always`         | Always restart, including after Docker daemon restart.                   |
| `unless-stopped` | Like `always`, but if I manually stop it, it stays stopped after reboot. |

I used `unless-stopped` because I want lab services to survive a WSL restart, but if I deliberately `docker compose stop` a service, I don't want it auto-restarting.

### Volumes (top-level)
```yaml
volumes:
  app_data:
  redis_data:
```

Named volumes declared at the top level. Compose creates them if they don't exist. Data persists across `docker compose down` — volumes are only removed with `docker compose down -v`. The actual volume name gets prefixed with the project name (directory name by default), so `app_data` becomes `app_app_data`.

## Networking in Compose
Compose automatically creates a bridge network for the stack (named `<project>_default`). All services are connected to it. Services can reach each other by **service name** — Compose runs an embedded DNS server that resolves service names to container IPs.

This is why `REDIS_HOST=redis` works. The app connects to `redis:6379`, and Docker DNS resolves `redis` to the Redis container's IP on the Compose network. No manual `docker network create` needed.

When I run `docker compose down`, the network is removed. When I run `docker compose up`, it's recreated. The network is ephemeral — it exists only while the stack is running.

## How I updated the app for Compose
The Week 02 app wrote visit timestamps to a file. For Week 03, I added Redis as a cache:

```python
cache = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
```

`decode_responses=True` makes the Redis client return strings instead of bytes. Without this, `cache.get("visit_count")` returns `b"42"` instead of `"42"`.

```python
visits = cache.incr("visit_count")
```

`INCR` is an atomic Redis command. It increments the value of `visit_count` by 1 and returns the new value. If the key doesn't exist, Redis creates it with value 0 first, then increments. Atomic means even with concurrent requests, no count is lost.

The `/health` endpoint now checks Redis connectivity:

```python
try:
    cache.ping()
    redis_status = "connected"
except redis.ConnectionError:
    redis_status = "disconnected"
```

`PING` is the simplest Redis command — it returns `PONG` if the connection is alive. Wrapping it in try/except means the health endpoint still returns 200 even if Redis is down (so Docker can see the app is up but Redis is not, rather than the whole healthcheck failing).

## Key Compose commands I used
```bash
docker compose up -d --build
```

Start the stack in detached mode, rebuilding images first. Without `--build`, Compose reuses the cached image even if the code changed. I always use `--build` during development.

```bash
docker compose down
```

Stop containers, remove them, and remove the default network. Volumes are preserved. Add `-v` to also remove volumes.

```bash
docker compose ps
```

Show running services, their status, ports, and health. The `(healthy)` label confirmed my healthchecks were passing.

```bash
docker compose logs
docker compose logs app
docker compose logs -f
```

View logs. Without a service name, shows combined logs from all services (interleaved). `-f` follows in real time.

```bash
docker compose exec app sh
docker compose exec redis redis-cli ping
```

Run a command inside a running container. `exec` attaches to an existing container (unlike `run`, which creates a new one).

## What I observed in the logs
1. Redis started first and printed its initialization sequence (loading RDB, accepting connections).
2. Compose waited for the Redis healthcheck (`redis-cli ping`) to pass before starting the app — I saw `Container fp-redis Healthy` followed by the app starting.
3. The app's healthcheck probe (`GET /health` from `127.0.0.1`) appeared in the logs every ~10 seconds — that's the interval I configured.
4. Browser requests came from `172.18.0.1` (the Docker bridge gateway IP, which is how the host appears to containers on the bridge network).
5. Redis printed a warning about `vm.overcommit_memory` — this is a WSL2 limitation, not an error. Redis recommends enabling memory overcommit to avoid background save failures under low memory, but for a lab it's harmless.
6. On `docker compose down`, Redis saved a final RDB snapshot (`DB saved on disk`) before shutting down. This is why the visit count survives restarts — Redis persists to the named volume.

## Difference between `docker compose` and `docker-compose`
- `docker-compose` (hyphenated): the old standalone Python tool (Compose V1). Deprecated.
- `docker compose` (space): the new Go plugin built into Docker CLI (Compose V2). This is what I used.

The commands are almost identical, but V2 is faster and uses `docker compose` instead of `docker-compose`. V2 is the default in modern Docker Desktop and Docker Engine installs.

## What would be different in production
- I wouldn't hardcode `redis:7-alpine` without a SHA pin — in production, I'd use `redis:7-alpine@sha256:...` for reproducibility.
- I'd use a `.env` file or external secret management instead of inline environment variables.
- I'd add resource limits (`deploy.resources.limits`) to prevent a single service from consuming all host memory.
- I'd put a reverse proxy (nginx/traefik) in front of the app instead of exposing port 8000 directly.
- For real multi-host deployments, I'd use Kubernetes, not Compose. Compose is single-host only.
