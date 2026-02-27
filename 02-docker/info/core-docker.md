# Core Docker workflow (Week 02)
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

docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev

docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/

docker rm -f fp-hello-api
docker network rm fp-net
```

## Cleanup
Inspect and clean local Docker resources.

```bash
# inspect
docker ps -a
docker images
docker volume ls
docker network ls

# clean targeted resources
docker rm fp-hello-api
docker rm -f fp-hello-api
docker rmi fp-hello-api:dev
docker volume rm fp_hello_data
docker network rm fp-net

# prune unused resources
docker container prune
docker image prune
docker volume prune
docker system prune
docker system prune -a --volumes
```

## Troubleshooting
### Port bind error (`0.0.0.0:8000` already in use)
```bash
docker ps --format '{{.Names}} {{.Ports}}'
ss -ltnp | rg ':8000'
```
Fix by stopping conflicting process/container or mapping another host port.

### Container exits immediately
```bash
docker ps -a --format '{{.Names}} {{.Status}}'
docker logs fp-hello-api
```
Fix by checking entrypoint/command/runtime errors and rebuilding image if needed.

### Data does not persist
```bash
docker inspect fp-hello-api | rg -n 'Mounts|Source|Destination'
docker volume ls
```
Fix by verifying named volume exists and is mounted to `/data`.

### Container DNS fails on custom network
```bash
docker network inspect fp-net
docker ps --format '{{.Names}} {{.Networks}}'
```
Fix by ensuring both containers join the same user-defined network.
