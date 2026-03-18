# Live project idea — deploy target for the FreePlayground pipeline
## The idea
Host a real project (personal portfolio site) that the FreePlayground CI/CD ecosystem builds, scans, and deploys. This gives the pipeline real commits, real uptime, and real consequence instead of only demo apps.

## Why a personal portfolio site
- Low app complexity, high DevOps value — the site stays simple so the pipeline stays the focus.
- Natural commit flow — every FreePlayground week produces something to showcase, which triggers real CI/CD runs.
- Career proof — recruiters see a live site deployed through a pipeline I built. The site IS the proof.
- Fits `11-backend-lab/` — already reserved in the game plan for "a tiny API used as the anchor app for containers/CI/K8s/security."

## What the site could include
- Name, title, short intro.
- Links to GitHub/GitLab, LinkedIn, etc.
- A "what I built" section that grows as FreePlayground weeks ship.
- Optional: a blog/notes section for writeups.
- Optional: a `/health` endpoint so the monitoring stack has something real to scrape.

## Tech stack options
| Option | Stack | Pros | Cons |
| --- | --- | --- | --- |
| Static site | Hugo / Astro / plain HTML+CSS | Tiny image, fast, free hosting (GitHub Pages, Cloudflare Pages) | No backend to exercise K8s service mesh / API scanning |
| FastAPI + static | FastAPI serving a small API + static frontend | Already familiar from 02-docker, has endpoints for health/metrics | Slightly more to maintain |
| Next.js / SvelteKit | JS framework with SSR | Modern, good portfolio templates | Adds Node.js to the stack, heavier image |

My current lean: **FastAPI + static frontend**. Reuses the Python stack I already know, gives real API endpoints for scanning and monitoring, and keeps the Docker image small with a multistage build.

## Where it would live
### Option A: inside FreePlayground (`11-backend-lab/`)
- Single repo. Pipeline config and app code live together.
- Simpler to start. One clone, one CI config.
- Downside: not how production repos are structured (app and infra are usually separate).

### Option B: separate repo, deployed by FreePlayground's pipeline
- App repo holds the site code + Dockerfile.
- FreePlayground repo holds the K8s manifests, Helm values, and CD config.
- ArgoCD watches FreePlayground for manifest changes, pulls the image from a registry.
- More realistic GitOps pattern. Closer to what I'd see at a job.
- Downside: two repos to manage.

### Suggested path
Start with Option A during Phase B/C to keep things simple. Split into Option B when I reach the ArgoCD/GitOps weeks (Phase C/D) — that split itself becomes a learning exercise.

## Free hosting targets
| Platform | Type | Cost | Notes |
| --- | --- | --- | --- |
| GitHub Pages | Static only | Free | Easy, but no container deploy (good for static option) |
| Cloudflare Pages | Static + serverless | Free tier | Fast CDN, auto-deploy from git |
| Oracle Cloud free tier | VM (ARM, 4 CPU, 24 GB RAM) | Always free | Can run K8s (k3s) on it — real deploy target |
| Azure free tier | App Service (F1) | Free (limited) | 60 min/day compute, good for demo |
| Fly.io | Container hosting | Free tier (3 shared VMs) | Simple container deploy, no K8s needed |
| Railway | Container hosting | Free trial/$5 credit | Easy Docker deploy |

For a real K8s deploy target, **Oracle Cloud free tier** is the strongest option — enough resources to run k3s + the app + monitoring.

## What the pipeline would do end to end
```push code to app repo
  → CI triggers
    → lint + test
    → SAST + dependency scan
    → build container image (multistage)
    → scan image (Trivy)
    → push image to registry (GitLab CR or GHCR)
  → CD triggers
    → update image tag in K8s manifest (FreePlayground repo)
    → ArgoCD syncs manifest to cluster
    → app deploys to K8s
  → monitoring
    → Prometheus scrapes /health and /metrics
    → Grafana dashboard shows uptime + latency
    → alert fires if site goes down
```

## When to start
- **Not now.** Current focus is Phase A (foundations + Docker + Compose).
- **Phase B (Weeks 05-08):** set up local K8s cluster. Deploy the site locally as the first real workload.
- **Phase C (Weeks 09-12):** wire the CI pipeline to build and push the image. Deploy via CD job.
- **Phase D onward:** add scanning, GitOps split, monitoring, and hardening with the site as the live target.

## Checklist for when I start
- [ ] Decide static vs FastAPI (lean: FastAPI).
- [ ] Scaffold the app in `11-backend-lab/` with Dockerfile + health endpoint.
- [ ] Add a CI job that builds and pushes the image.
- [ ] Deploy to local k3s/kind first.
- [ ] Pick a free cloud host for public deploy.
- [ ] Split into separate repo if doing GitOps (Option B).
- [ ] Wire monitoring (Prometheus + Grafana) to the live site.
