# Docker fundamentals (Week 02)

This folder captures my Docker basics: building images, running containers, reading logs, using volumes, and basic networking.

## Build
```bash
docker build -t fp-hello-api:dev ./app
```

## Run
```bash
docker run --rm -p 8000:8000 --name fp-hello-api fp-hello-api:dev
```

## Logs
```bash
docker logs fp-hello-api
docker logs -f fp-hello-api
```

## Volumes (persistence)
```bash
docker volume create fp_hello_data

docker run --rm -p 8000:8000 --name fp-hello-api \
  --mount type=volume,src=fp_hello_data,dst=/data \
  fp-hello-api:dev
```

## Networks (user-defined bridge)
```bash
docker network create fp-net

docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev

docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/

docker rm -f fp-hello-api
docker network rm fp-net
```

## Cleanup
```bash
docker ps -a
docker images
docker volume ls
docker network ls
```

Docker command references (build/run/logs/volumes) are straight from Docker’s CLI docs.
