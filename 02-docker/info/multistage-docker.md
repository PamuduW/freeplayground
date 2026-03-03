# Multistage Docker build notes
## Why multistage is used
A multistage build separates dependency build steps from runtime image creation. This helps reduce runtime image size and keeps the final image cleaner.

## File in this module
- `02-docker/app/Dockerfile.multistage`

Current stages:
1. `builder` stage: builds Python wheels from `requirements.txt`.
2. `runtime` stage: installs prebuilt wheels, copies app code, and runs `uvicorn`.

## Build and run
```bash
docker build -f 02-docker/app/Dockerfile.multistage -t fp-hello-api:ms ./02-docker/app
# -f: path to the Dockerfile to use (overrides the default ./Dockerfile)
# -t fp-hello-api:ms: tag the resulting image; :ms distinguishes it from the single-stage :dev build
# ./02-docker/app: build context — Docker sends this directory to the daemon for COPY instructions

docker run --rm -p 8000:8000 --name fp-hello-api-ms fp-hello-api:ms
# --rm: auto-remove container on exit so stopped containers don't pile up
# -p 8000:8000: map host:container ports
# --name: give the container a fixed name for easy log/inspect/rm commands
```

## Validate behavior
```bash
curl -sS http://localhost:8000/
# -s: silent (no progress bar); -S: still show errors if they occur
curl -sS http://localhost:8000/health
# hit the /health endpoint to confirm the app responds with its health check payload
```

## Compare image sizes
```bash
docker images | rg 'fp-hello-api'
# list all local images and filter for fp-hello-api tags
# compare SIZE column: :dev (single-stage) should be larger than :ms (multistage)
```
Compare `fp-hello-api:dev` (single-stage) vs `fp-hello-api:ms` (multistage).

## Common pitfalls
### Missing files in runtime stage
If runtime container fails due to missing files, verify `COPY --from=builder ...` paths and final `COPY main.py .`.

### Wheels not built correctly
If wheel build fails, verify dependency names in `requirements.txt` and network access during build.

### Wrong build context
Use `./02-docker/app` as context when Dockerfile expects local files from that directory.
