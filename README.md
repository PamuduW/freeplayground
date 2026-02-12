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
- `docs/weekly/` - weekly notes and progress receipts

## Planned modules
- `01-foundations/` - Linux, networking basics, scripting notes
- `02-docker/` - Docker labs and Compose demos
- `03-gitlab-ci/` - GitLab CI patterns and examples
- `04-security-ci/` - security in CI experiments
- `05-kubernetes/` - k8s labs, troubleshooting, security basics
- `06-observability/` - metrics, logs, dashboards
- `07-terraform/` - IaC structure and cloud baselines
- `10-automation-scripts/` - reusable scripts and mini tools

## Weekly log
- [Week 01](docs/weekly/week-01.md)

## How I work
- WSL-first workflow: development and tooling run inside Linux (WSL).
- Progress is quota-based: finish the weekly deliverable, not "work every day".
- Plan is dynamic, goals are fixed: scope can change, outcomes stay the same.

## Weekly Git workflow
- I create a week branch: `week/NN-short-theme`.
- I open a Draft merge request to `main` at the start of the week.
- I merge to `main` at the end of the week using a merge commit, then delete the week branch.

## CI badge setup
This repo uses a GitLab pipeline badge so the build health is visible at a glance. See the start of this README.md file to see the active badge.
