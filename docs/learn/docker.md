# Docker — what I learned (Week 02)
## What Docker actually is
Docker runs applications inside containers. A container is an isolated process that has its own filesystem, network, and process tree, but shares the host kernel. It is not a virtual machine — there is no guest OS.

Key difference from a VM:
- VM: Host → Hypervisor → Guest OS → App (heavy, slow boot)
- Container: Host → Docker engine → App (lightweight, instant start)

## How a Docker image is built
An image is a read-only template. It is built in layers. Every instruction in a Dockerfile creates a new layer on top of the previous one. Layers are cached — if nothing changed in a layer, Docker reuses it from cache instead of rebuilding.

### My Dockerfile (single-stage) — line by line
```dockerfile
FROM python:3.12-slim
```
Start from an existing base image. `python:3.12-slim` is a Debian-based image with Python pre-installed. The `slim` variant strips docs/extras to keep the image smaller (~120 MB vs ~900 MB for the full image).

```dockerfile
WORKDIR /app
```
Set the working directory inside the container. All following commands (`COPY`, `RUN`, `CMD`) execute relative to `/app`. If `/app` does not exist, Docker creates it.

```dockerfile
COPY requirements.txt .
```
Copy `requirements.txt` from the build context (my local `./app` folder) into the container's `/app/`. This is copied before the app code so that the `pip install` layer is cached — if dependencies didn't change, Docker skips the install on rebuild.

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt
```
Run a command during build. This installs Python dependencies. `--no-cache-dir` tells pip to skip saving download caches, keeping the layer smaller.

```dockerfile
COPY main.py .
```
Copy the app source code. This comes after `pip install` so changing `main.py` does not invalidate the dependency cache layer.

```dockerfile
RUN mkdir -p /data
```
Create the `/data` directory so the volume mount point exists even if no volume is attached.

```dockerfile
EXPOSE 8000
```
Metadata only. Documents that the container listens on port 8000. Does NOT actually publish the port — that requires `-p` at runtime.

```dockerfile
CMD ["uvicorn", "main:app", "--host=0.0.0.0", "--port=8000"]
```
Default command when the container starts. Uses exec form (JSON array) so uvicorn runs as PID 1 and receives signals properly. `main:app` means "from `main.py`, import the `app` object". `--host=0.0.0.0` makes the server listen on all interfaces inside the container (required for `-p` port mapping to work).

### My Dockerfile.multistage — what's different
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip wheel --wheel-dir /wheels -r requirements.txt
```
**Stage 1 (builder)**: installs build tools, compiles dependencies into `.whl` files (pre-built packages). The `AS builder` names this stage so the next stage can reference it.

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* && rm -rf /wheels
```
**Stage 2 (runtime)**: starts from a clean base image. `COPY --from=builder` pulls only the built wheels from stage 1. Everything else from the builder stage (build tools, source caches) is thrown away. This is why the final image is smaller.

The rest is identical to the single-stage Dockerfile.

### Why multistage matters
The builder stage may pull in compilers, header files, and build caches that are only needed during `pip wheel`. The runtime stage only has the final installed packages. For a real app with C-extension dependencies (like `cryptography`, `numpy`), the size difference can be hundreds of MB.

## The app itself
`main.py` is a FastAPI app with two endpoints:
- `GET /` — writes a timestamp to `/data/visits.log` and returns JSON. This endpoint exists to make the volume demo real: if `/data` is backed by a named volume, the log survives container restarts.
- `GET /health` — returns `{"status": "up"}`. A health check endpoint.

`requirements.txt` pins two packages:
- `fastapi` — the web framework
- `uvicorn[standard]` — the ASGI server that runs FastAPI. The `[standard]` extra installs `uvloop` and `httptools` for better performance.

## .dockerignore
```text
__pycache__/
*.pyc
.venv/
.env
.git/
```
Works like `.gitignore` but for the Docker build context. When I run `docker build`, Docker packages the entire build context directory and sends it to the daemon. `.dockerignore` excludes files that should never end up in an image (caches, secrets, version control).

## Key runtime concepts
### Images vs containers
- **Image**: a read-only blueprint. Built once, reused many times. Stored locally in the Docker image cache.
- **Container**: a running (or stopped) instance of an image. Has its own writable layer on top of the read-only image layers. When the container is removed, the writable layer is gone.

### Port mapping (`-p 8000:8000`)
Format: `-p HOST_PORT:CONTAINER_PORT`. The container's internal network is isolated. `-p` creates a forwarding rule so traffic hitting `localhost:8000` on the host reaches port 8000 inside the container. Without `-p`, the container port is unreachable from the host.

### Detached vs foreground
- `docker run fp-hello-api:dev` — foreground. Logs stream to terminal. Ctrl-C stops the container.
- `docker run -d fp-hello-api:dev` — detached. Container runs in background. Use `docker logs` to see output.

### Volumes
Containers are ephemeral. When a container is removed, its writable layer is gone. Volumes solve this.

- **Named volume** (`docker volume create fp_hello_data`): Docker manages the storage on the host. Data survives container removal. Mounted with `--mount type=volume,src=fp_hello_data,dst=/data`.
- **Bind mount**: maps a host directory directly into the container. Useful for development (live code reload) but not portable.

Why the mount flag matters: `dst=/data` means the container sees the volume at `/data`. The app writes to `/data/visits.log`. If I stop the container, start a new one with the same volume, the log file is still there.

### Networks
By default, containers connect to the `bridge` network. Containers on the default bridge can talk to each other by IP, but NOT by name.

A **user-defined bridge** (`docker network create fp-net`) adds DNS resolution. Containers on the same user-defined bridge can reach each other by container name. This is why `wget http://fp-hello-api:8000/` works — Docker's embedded DNS resolves `fp-hello-api` to the container's IP on `fp-net`.

### Container lifecycle
```text
docker run   → creates + starts a container
docker stop  → sends SIGTERM, waits 10s, then SIGKILL
docker start → restarts a stopped container
docker rm    → removes a stopped container
docker rm -f → sends SIGKILL + removes (shortcut)
```
`--rm` on `docker run` auto-removes the container when it exits, so stopped containers don't pile up.

## Build context
When running `docker build -t fp-hello-api:dev ./02-docker/app`, the path `./02-docker/app` is the **build context**. Docker tars up this entire directory and sends it to the Docker daemon. The Dockerfile's `COPY` instructions can only access files inside this context. That's why `.dockerignore` matters — it prevents large or sensitive files from being included.

## Layer caching
Docker caches each layer. On rebuild, if a layer's inputs haven't changed, Docker reuses the cached version. This is why the Dockerfile copies `requirements.txt` and runs `pip install` before copying `main.py`: dependencies change rarely, app code changes often. The install layer stays cached across most rebuilds.

If any layer changes, all layers after it are rebuilt. Order matters.
