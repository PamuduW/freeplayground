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

docker run --rm -p 8000:8000 --name fp-hello-api-ms fp-hello-api:ms
```

## Validate behavior
```bash
curl -sS http://localhost:8000/
curl -sS http://localhost:8000/health
```

## Compare image sizes
```bash
docker images | rg 'fp-hello-api'
```
Compare `fp-hello-api:dev` (single-stage) vs `fp-hello-api:ms` (multistage).

## Common pitfalls
### Missing files in runtime stage
If runtime container fails due to missing files, verify `COPY --from=builder ...` paths and final `COPY main.py .`.

### Wheels not built correctly
If wheel build fails, verify dependency names in `requirements.txt` and network access during build.

### Wrong build context
Use `./02-docker/app` as context when Dockerfile expects local files from that directory.
