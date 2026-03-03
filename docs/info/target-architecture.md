# Target architecture
This doc describes the end-state CI/CD ecosystem I am building across FreePlayground.
It is the north-star reference; the week-by-week plan lives in `FreePlayground_Game_Plan_v3.md`.

## Pipeline flow (end state)
```text
Developer
  │
  ├─ push code ──► Source repo (GitHub / GitLab)
  │                    │
  │                    ▼
  │               ┌─────────────────────────────────┐
  │               │         CI pipeline              │
  │               │                                  │
  │               │  1. Lint + unit tests            │
  │               │  2. SAST (static analysis)       │
  │               │  3. Dependency / SCA scan        │
  │               │  4. Build container image         │
  │               │  5. Image vulnerability scan      │
  │               │  6. Push image to registry        │
  │               └──────────────┬──────────────────-─┘
  │                              │
  │                              ▼
  │               ┌──────────────────────────────────┐
  │               │         CD pipeline               │
  │               │                                   │
  │               │  7. Update manifest / values file │
  │               │  8. GitOps sync (Argo CD)         │
  │               │  9. Deploy to Kubernetes           │
  │               └──────────────┬────────────────────┘
  │                              │
  │                              ▼
  │               ┌──────────────────────────────────┐
  │               │       Observability               │
  │               │                                   │
  │               │  10. Metrics  (Prometheus)         │
  │               │  11. Dashboards (Grafana)          │
  │               │  12. Logs (Loki or similar)        │
  │               │  13. Alerts → email / webhook      │
  │               └──────────────────────────────────-┘
```

### Flow summary
1. I push code to a feature or week branch.
2. The CI pipeline triggers automatically: lint, test, scan source, build image, scan image, push to registry.
3. On success the CD pipeline updates the Kubernetes manifest with the new image tag and commits it.
4. Argo CD detects the manifest change, syncs, and deploys to the cluster.
5. Prometheus scrapes metrics, Grafana visualises them, and alert rules notify me on failures.

## Toolchain map
Each row maps a pipeline responsibility to the tool I plan to use. The status column tracks
whether the tool is integrated in the repo yet.

| Role | Tool (primary) | Alternatives considered | Status |
| --- | --- | --- | --- |
| Source control | GitHub + GitLab mirror | - | done |
| CI orchestration | GitLab CI | Jenkins, GitHub Actions | in progress |
| Linting / formatting | pre-commit, markdownlint, Prettier, yamllint | - | done |
| Unit / integration tests | pytest (Python app) | - | planned |
| SAST | GitLab SAST / Semgrep | SonarQube | planned |
| Dependency / SCA scan | OWASP Dependency-Check / Trivy | Snyk | planned |
| Container build | Docker (multi-stage) | Buildah, kaniko | done |
| Image vulnerability scan | Trivy | Grype | planned |
| Container registry | GitLab Container Registry | Docker Hub, GHCR | planned |
| CD orchestration | Argo CD (GitOps) | Flux, Jenkins CD job | planned |
| Kubernetes runtime | kind / k3s (local) | minikube | planned |
| Helm packaging | Helm | Kustomize | planned |
| Infrastructure as Code | Terraform | Pulumi | planned |
| Metrics | Prometheus | - | planned |
| Dashboards | Grafana | - | planned |
| Log aggregation | Loki | EFK stack | planned |
| Alerting | Grafana alerting / Alertmanager | PagerDuty | planned |
| Secrets management | cloud-native secret store (Azure KV / AWS SSM) | HashiCorp Vault | planned |
| Policy / compliance | OPA / policy-as-code (Terraform lint) | - | planned |

## Module coverage map
Shows which repo module implements which part of the pipeline.

| Pipeline stage | Repo module | Key artifacts |
| --- | --- | --- |
| Containerisation | `02-docker/` | Dockerfile, Dockerfile.multistage, compose files |
| CI jobs (lint, test, build, scan) | `03-ci-cd/` | `.gitlab-ci.yml`, job templates |
| Security scanning in CI | `04-security-ci/` | SAST config, dependency scan config, image scan |
| Kubernetes deploy | `05-kubernetes/` | manifests, RBAC, network policies, Helm charts |
| Observability stack | `06-observability/` | Prometheus, Grafana, Loki configs, dashboards |
| Infrastructure as Code | `07-terraform/` | modules, state config, networking |
| Helm (if split from K8s) | `08-helm/` | charts, values files |
| Cloud labs | `09-cloud/` | architecture docs, teardown checklists |
| Automation / helper scripts | `10-automation-scripts/` | bash/python utilities |
| Anchor application | `11-backend-lab/` | small API used as the deploy target |
| Foundations (Linux, Git) | `01-foundations/` | notes, scripts |

## Constraints and decisions
- **Local-first**: the default target cluster is local (kind / k3s). Cloud deploy is optional and always torn down after labs.
- **Cost zero by default**: no cloud resource should stay running outside an active lab session. Teardown checklists live in weekly logs and `09-cloud/`.
- **GitOps model**: the CD side follows GitOps — a Git commit is the single source of truth for what is deployed.
- **Tool choices are flexible**: the primary tool column reflects my current plan. If a better free-tier option appears, I swap it and update this doc.
