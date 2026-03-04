# Core Docker workflow (Week 02)
These standalone Docker commands work without Redis. The app detects that `REDIS_HOST` is not set and falls back to in-memory visit counting. For the full Redis-backed stack, see `docker-compose.md`.

## Build
Build an image from the Dockerfile in `./app` and tag it as `fp-hello-api:dev`.

```bash
docker build -t fp-hello-api:dev ./app
# -t: tag the image (name:tag format)
# ./app: build context path containing Dockerfile
```

## Run
Create and start a container from the image, mapping port 8000 and auto-removing on exit.

```bash
docker run --rm -p 8000:8000 --name fp-hello-api fp-hello-api:dev
# --rm: auto-remove container when it stops
# -p 8000:8000: map host port 8000 to container port 8000
# --name: assign custom container name
```

Test endpoints:
- [http://localhost:8000/](http://localhost:8000/)
- [http://localhost:8000/health](http://localhost:8000/health)

## Logs
View container logs.

```bash
docker logs fp-hello-api          # show log history
docker logs -f fp-hello-api       # stream logs
```

## Volumes (persistence)
Create a named volume and mount it to `/data`.

```bash
docker volume create fp_hello_data

docker run --rm -p 8000:8000 --name fp-hello-api \
  --mount type=volume,src=fp_hello_data,dst=/data \
  fp-hello-api:dev
# type=volume: named volume
# src=fp_hello_data: source volume
# dst=/data: mount path in container
```

## Networks (user-defined bridge)
Create a custom network and verify container-to-container DNS.

```bash
docker network create fp-net
# create a user-defined bridge network named fp-net
# containers on the same user-defined bridge can resolve each other by name

docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev
# -d: run in detached (background) mode
# --network fp-net: attach this container to the fp-net bridge network
# the container is reachable by its --name from any other container on fp-net

docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/
# spin up a throwaway busybox container on the same network
# wget -qO-: quietly fetch the URL and print to stdout (dash means stdout)
# http://fp-hello-api:8000/ uses Docker DNS — resolves because both containers share fp-net

docker rm -f fp-hello-api
# -f: force-remove the container even if it is still running (sends SIGKILL)
docker network rm fp-net
# remove the custom network (fails if any containers are still attached)
```

## Cleanup
Inspect and clean local Docker resources.

```bash
# --- inspect ---
docker ps -a
# list all containers (running + stopped); without -a only running are shown
docker images
# list locally cached images with repo, tag, and size
docker volume ls
# list all named volumes managed by Docker
docker network ls
# list all networks (bridge, host, none, plus any user-defined)

# --- clean targeted resources ---
docker rm fp-hello-api
# remove a stopped container by name or ID
docker rm -f fp-hello-api
# -f: force-remove even if the container is still running
docker rmi fp-hello-api:dev
# remove a local image by name:tag; fails if a container still references it
docker volume rm fp_hello_data
# remove a named volume; fails if any container is using it
docker network rm fp-net
# remove a user-defined network; fails if any container is still attached

# --- prune unused resources ---
docker container prune
# remove all stopped containers
docker image prune
# remove dangling images (untagged layers not referenced by any image)
docker volume prune
# remove all volumes not currently mounted to a container (use with caution)
docker system prune
# remove stopped containers, unused networks, and dangling images in one pass
docker system prune -a --volumes
# -a: also remove all unused images (not just dangling)
# --volumes: also remove unused volumes — destructive, double-check before running
```

## Troubleshooting
### Port bind error (`0.0.0.0:8000` already in use)
```bash
docker ps --format '{{.Names}} {{.Ports}}'
# list running containers showing only name and port mappings
# use Go template syntax — {{.Names}} and {{.Ports}} are Docker format fields
ss -ltnp | rg ':8000'
# ss: socket statistics; -l listening, -t TCP, -n numeric, -p show process
# pipe through ripgrep to filter for port 8000
```
Fix by stopping conflicting process/container or mapping another host port (`-p 9000:8000`).

### Container exits immediately
```bash
docker ps -a --format '{{.Names}} {{.Status}}'
# -a: include stopped containers; Status shows exit code and uptime
docker logs fp-hello-api
# print stdout/stderr captured from the container — check for stack traces or crash messages
```
Fix by checking entrypoint/command/runtime errors and rebuilding image if needed.

### Data does not persist
```bash
docker inspect fp-hello-api | rg -n 'Mounts|Source|Destination'
# inspect returns full container JSON; filter for mount-related fields
# Source = host/volume path, Destination = path inside the container
docker volume ls
# confirm the named volume actually exists
```
Fix by verifying named volume exists and is mounted to `/data`.

### Container DNS fails on custom network
```bash
docker network inspect fp-net
# shows network config, subnet, and list of attached containers
docker ps --format '{{.Names}} {{.Networks}}'
# verify which network each running container is attached to
```
Fix by ensuring both containers join the same user-defined network.
