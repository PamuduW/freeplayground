# Week 02 - Docker fundamentals

## Goal
Ship my Docker fundamentals notes plus one small Dockerized app I can build and run locally.

## Must ship (definition of done)
- [ ] 02-docker/README.md with build/run/logs/volumes/networks
- [ ] One Dockerized simple app (02-docker/app/)
- [ ] Evidence captured (commands + screenshots + links)

## Stretch (nice to have)
- [ ] Multi-stage Docker build

## What I did (short log)
-
-
-

## What I learned
-
-
-

## Notes / commands / snippets
```bash
# build
docker build -t fp-hello-api:dev ./02-docker/app

# run
docker run --rm -p 8000:8000 --name fp-hello-api fp-hello-api:dev

# logs
docker logs -f fp-hello-api

# volumes
docker volume create fp_hello_data
docker run --rm -p 8000:8000 --name fp-hello-api \
  --mount type=volume,src=fp_hello_data,dst=/data \
  fp-hello-api:dev

# networks (basic demo)
docker network create fp-net
docker run -d --name fp-hello-api --network fp-net -p 8000:8000 fp-hello-api:dev
docker run --rm --network fp-net busybox:1.36 wget -qO- http://fp-hello-api:8000/
docker rm -f fp-hello-api
docker network rm fp-net
```

## Evidence (links + screenshots)
- Links:
  - GitHub: <link>
  - GitLab: <link>
  - Pipeline: <link>
  - MR: <link>
  - Tag (optional): week-02

- Screenshots:
  - docker build success
  - container running + curl output
  - docker logs output
  - docker volume ls + proof data persists
  - docker network ls + busybox -> app request

## Retro
- Went well:
  - 

- Needs improvement:
  - 

- Next week adjustment (scope can change, outcome stays):
  - 
