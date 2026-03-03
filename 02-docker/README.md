# Docker fundamentals (Week 02)
This module covers practical Docker fundamentals used in this repo: building images, running containers, reading logs, managing volumes, and container networking.

In this repo, Docker is used to containerize the sample FastAPI app under `02-docker/app/` and run repeatable local experiments for container lifecycle and operations.

## Quick workflow
Run these from repo root unless noted.

### Build
```bash
docker build -t fp-hello-api:dev ./02-docker/app
# -t: tag the image as fp-hello-api:dev
# ./02-docker/app: build context containing Dockerfile and app source
```

### Run
```bash
docker run --rm -p 8000:8000 --name fp-hello-api fp-hello-api:dev
# --rm: auto-remove container on exit
# -p 8000:8000: map host port to container port
# --name: assign a fixed container name for easy reference
```

### Logs
```bash
docker logs fp-hello-api        # show captured log history
docker logs -f fp-hello-api     # -f: follow/stream logs in real time (Ctrl-C to stop)
```

### Volumes
```bash
docker volume create fp_hello_data
# create a named volume managed by Docker

docker run --rm -p 8000:8000 --name fp-hello-api \
  --mount type=volume,src=fp_hello_data,dst=/data \
  fp-hello-api:dev
# --mount: declarative mount syntax (preferred over -v)
# type=volume: use a Docker-managed named volume
# src: volume name, dst: mount point inside the container
```

### Networks
```bash
docker network create fp-net
# create a user-defined bridge network (enables container DNS)

docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev
# -d: detached mode; --network: attach to fp-net bridge

docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/
# verify DNS resolution — busybox resolves fp-hello-api by container name on fp-net

docker rm -f fp-hello-api       # force-remove the running container
docker network rm fp-net        # remove the custom network
```

## Module docs map
- `info/_index.md` - navigation for module docs.
- `info/core-docker.md` - detailed commands, flags, workflow, and troubleshooting for day-to-day Docker usage.
- `info/multistage-docker.md` - multistage Dockerfile pattern used in this module and when to apply it.

## App location
- `app/Dockerfile`
- `app/Dockerfile.multistage`
- `app/main.py`
- `app/requirements.txt`
