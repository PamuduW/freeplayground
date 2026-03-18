# FreePlayground
[![pipeline status](https://gitlab.com/PamuduW/freeplayground/badges/main/pipeline.svg)](https://gitlab.com/PamuduW/freeplayground/-/pipelines)

FreePlayground is my public engineering lab notebook and proof-of-work repo.

It captures weekly progress across DevOps fundamentals, cloud, automation, and security, plus the projects and experiments I build along the way.

## What's inside
### 1) DevOps foundations
Linux, Git workflows, containers, CI/CD, infrastructure hygiene.

### 2) Cloud skills
Hands-on labs and notes across Azure and AWS, with cost guardrails and teardown discipline.

### 3) DevSecOps and Cloud Security
Security checks in CI, secure configuration, identity and access basics, supply chain security concepts.

### 4) Automation
Small tools and scripts (Bash and Python) that solve real problems and reduce manual work.

### 5) Portfolio evidence
Each week ends with a shippable outcome: a commit, documentation, and repeatable steps.

## Repo map
Current module folders:
- `02-docker/` - Docker labs and Compose demos
- `10-automation-scripts/` - reusable scripts and mini tools

Other repo areas:
- `docs/weekly/` - weekly notes and progress receipts
- `docs/info/` - repo-level plan, workflow notes, and templates
- `*/info/` - module-specific notes and runbooks (for example: `02-docker/info/`)
- `docs/info/tree.md` - latest quick snapshot of repo folder structure

## Planned modules map
- `01-foundations/` - Linux, networking basics, scripting notes
- `02-docker/` - Docker labs and Compose demos (current)
- `03-ci-cd/` - GitLab CI patterns and examples
- `04-security-ci/` - security in CI experiments
- `05-kubernetes/` - k8s labs, troubleshooting, security basics
- `06-observability/` - metrics, logs, dashboards
- `07-terraform/` - IaC structure and cloud baselines
- `08-helm/` - optional Helm-focused module if Helm labs grow large
- `09-cloud/` - AWS and Azure labs, architecture notes, and teardown checklists
- `10-automation-scripts/` - reusable scripts and mini tools
- `11-backend-lab/` - optional small API used as an anchor app for containers/CI/K8s/security

## Weekly log
- [Week 01](docs/weekly/week-01.md)
- [Week 02](docs/weekly/week-02.md)
- [Week 02 Add-on 01 (linting/formatting)](docs/weekly/week-02-addon-01.md)
- [Week 03](docs/weekly/week-03.md)

## Repo links and hosting
- **GitLab (primary):** https://gitlab.com/PamuduW/freeplayground
- **GitHub (mirror):** https://github.com/PamuduW/freeplayground

GitLab is the development origin — cloning, branches, merge requests, and CI all happen here. GitLab repo mirroring pushes every change to the GitHub mirror automatically. GitHub is used for its free security features (CodeQL, Dependabot alerts, secret scanning, code scanning). No pull requests or branches are created on the GitHub side.

## Working style
- WSL-first workflow: development and tooling run inside Linux (WSL).
- Progress is quota-based: finish the weekly deliverable, not "work every day".
- Plan is dynamic, goals are fixed: scope can change, outcomes stay the same.
- Module technical README files are written in a detailed style (commands, actions, and troubleshooting).

## Weekly Git workflow
- A week branch is created using `week/NN-short-theme`.
- A Draft merge request to `main` is opened at the start of the week.
- The week branch is merged to `main` at week end using a merge commit and tagged with `make tag-week WEEK=NN`.

## Quality workflow
- Run `make hooks` once after cloning to install commit hooks.
- Run `make qa` before pushing or opening merge requests.
- `pre-commit` runs automatically on each commit.
- Quality setup details live in `docs/info/linting-formatting-workflow.md`.

## CI badge setup
This repo uses a GitLab pipeline badge so the build health is visible at a glance. See the start of this README.md file to see the active badge.
