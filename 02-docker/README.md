# Docker fundamentals (Week 02)

This folder captures my Docker basics: building images, running containers, reading logs, using volumes, and basic networking.

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
Here are the urls to test: 
- http://localhost:8000/
- http://localhost:8000/health

## Logs
View container output/logs.
```bash
docker logs fp-hello-api          # Show all past logs and exit
docker logs -f fp-hello-api       # Follow logs in real-time (like tail -f)
```

## Volumes (persistence)
Create a named volume for persistent data storage across container restarts.
```bash
# Create a Docker-managed volume
docker volume create fp_hello_data

# Run container with volume mounted at /data (where app writes visits.log)
docker run --rm -p 8000:8000 --name fp-hello-api \
  --mount type=volume,src=fp_hello_data,dst=/data \
  fp-hello-api:dev
# type=volume: use a named volume
# src=fp_hello_data: source volume name
# dst=/data: destination mount point inside container
```

## Networks (user-defined bridge)
Create a custom network for container-to-container communication with DNS resolution.
```bash
# Create user-defined bridge network
docker network create fp-net

# Run API container in detached mode on custom network
docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev
# -d: detached mode (run in background)

# Test inter-container networking: busybox calls API by container name
docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/
# wget -qO-: download and output to stdout
# http://fp-hello-api:8000/: DNS resolves container name on custom network

# Cleanup: force-remove container and network
docker rm -f fp-hello-api         # -f: force stop and remove
docker network rm fp-net
```

## Cleanup
List all Docker resources to inspect and manage your system.
```bash
# List resources
docker ps -a              # List all containers (running + stopped)
docker images             # List all images
docker volume ls          # List all volumes
docker network ls         # List all networks

# Delete specific resources (volumes/networks persist after container deletion)
docker rm fp-hello-api              # Remove stopped container
docker rm -f fp-hello-api           # Force remove running container
docker rmi fp-hello-api:dev         # Remove image
docker volume rm fp_hello_data      # Remove volume (deletes data!)
docker network rm fp-net            # Remove network (only if no containers attached)

# Prune unused resources
docker container prune              # Remove all stopped containers
docker image prune                  # Remove dangling images
docker volume prune                 # Remove unused volumes
docker system prune                 # Remove all unused containers, networks, images
docker system prune -a --volumes    # Nuclear option: remove everything unused
```

Docker command references (build/run/logs/volumes) are straight from Docker’s CLI docs.
