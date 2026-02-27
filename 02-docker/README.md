# Docker fundamentals (Week 02)
This module covers practical Docker fundamentals used in this repo: building images, running containers, reading logs, managing volumes, and container networking.

In this repo, Docker is used to containerize the sample FastAPI app under `02-docker/app/` and run repeatable local experiments for container lifecycle and operations.

## Quick workflow
Run these from repo root unless noted.

### Build
```bash
docker build -t fp-hello-api:dev ./02-docker/app
```

### Run
```bash
docker run --rm -p 8000:8000 --name fp-hello-api fp-hello-api:dev
```

### Logs
```bash
docker logs fp-hello-api
docker logs -f fp-hello-api
```

### Volumes
```bash
docker volume create fp_hello_data
docker run --rm -p 8000:8000 --name fp-hello-api \
  --mount type=volume,src=fp_hello_data,dst=/data \
  fp-hello-api:dev
```

### Networks
```bash
docker network create fp-net
docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev
docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/
docker rm -f fp-hello-api
docker network rm fp-net
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
