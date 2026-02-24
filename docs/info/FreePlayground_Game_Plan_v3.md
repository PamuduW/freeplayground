# FreePlayground Game Plan (Weekly, 12 Months, No Dates) - v3

## Scope

A weekly proof-of-work path toward DevOps -> Kubernetes -> CI mastery -> DevSecOps-
in-CI -> cloud security, using FreePlayground as the portfolio repo.

## Rules

- **Week numbering:** Week 01, Week 02, ... (Monday to Sunday). No dates stored in docs.
- **Writing rule:** Use first person (me / my / mine). Avoid second person (you / your).

## Repo links

- GitHub: https://github.com/PamuduW/freeplayground
- GitLab: https://gitlab.com/PamuduW/freeplayground

## Weekly shipping rhythm

- During week: keep notes in docs/weekly/ using docs/weekly/\_template.md.
- End of week: commit notes, add evidence (screenshots/links), write a mini retro.

## Weekly Git workflow (branch-per-week)

- Each week uses a branch named week/NN-short-theme (example: week/02-docker).
- A Draft merge request to main is opened at the start of the week.
- All week work is committed to the week branch.
- End of week: the MR is merged into main using a merge commit (no squash).
- After merge: the week branch is deleted.
- Optional: a tag week-NN is created on the merge commit.

## Recommended repo structure (full showcase layout to grow into)

- This is the full showcase layout to grow into:
- docs/weekly/ (weekly logs + \_template.md + images/)
- 01-foundations/ (Linux, networking, Git, scripting notes)
- 02-docker/ (Docker + Compose labs)
- 03-ci-cd/ (GitLab CI patterns, GitHub Actions comparisons)
- 04-security-ci/ (SAST, secrets, dependencies, SBOM, policy)
- 05-kubernetes/ (kubectl, manifests, troubleshooting, RBAC, Helm, ingress)
- 06-observability/ (logs, metrics, tracing, dashboards)
- 07-terraform/ (IaC patterns, modules, state, best practices)
- 08-helm/ (optional: if Helm grows large, keep separate from 05-kubernetes/)
- 09-cloud/ (AWS + Azure labs + architecture notes + teardown checklists)
- 10-automation-scripts/ (bash/python/go utilities, small tools)
- 11-backend-lab/ (optional: a tiny API used as the anchor app for containers/CI/K8s/security)

## Certificate track overlay (targets, adjustable)

| Certificate                 | Why it fits                                    | Prep window (weeks) | Exam target (week) |
| --------------------------- | ---------------------------------------------- | ------------------- | ------------------ |
| AZ-900 (Azure Fundamentals) | Cloud vocabulary + billing concepts early      | Week 02 - Week 04   | Week 04 - Week 05  |
| CKA (Kubernetes)            | Aligns with Kubernetes + troubleshooting phase | Week 05 - Week 12   | Week 12 - Week 14  |
| AWS Cloud Practitioner      | Cloud baseline before deeper AWS labs          | Week 17 - Week 20   | Week 20 - Week 22  |
| Terraform Associate         | Directly overlaps IaC phase                    | Week 21 - Week 24   | Week 24 - Week 26  |

## Phase order (updated)

- Phase A (Weeks 01 - 04): Foundations (repo + Linux + Git + Docker)
- Phase B (Weeks 05 - 08): Kubernetes core (incl. Helm intro)
- Phase C (Weeks 09 - 12): CI/CD mastery (GitLab CI focus)
- Phase D (Weeks 13 - 16): DevSecOps in CI (secure pipelines)
- Phase E (Weeks 17 - 20): Observability (metrics/logs/tracing)
- Phase F (Weeks 21 - 24): Terraform foundations (IaC)
- Phase G (Weeks 25 - 28): Cloud projects (AWS + Azure practice)
- Phase H (Weeks 29 - 32): Cloud security basics (IAM, network, secrets)
- Phase I (Weeks 33 - 36): Capstone hardening (runbooks, docs, polish)
- Weeks 37 - 52: Optional deep-dive track weeks (pick 1 track each week)

## Week-by-week plan

### Week 01 - Kickoff & setup

**Must ship**

- Create devsecops-lab repo + folder skeleton.
- Add docs/game-plan.md and docs/changelog.md.
- Confirm WSL repo location (~/projects/...).

**Stretch**

- Create GitLab.com mirror + run a "hello pipeline" job.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-01.md.

### Week 02 - Docker fundamentals

**Must ship**

- 02-docker/README.md with: build/run/logs/volumes/networks.
- One Dockerized simple app.

**Stretch**

- Add multi-stage Docker build.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-02.md.

### Week 03 - Docker Compose

**Must ship**

- Compose demo: app + DB (or app + cache).
- README: how to debug common failures.

**Stretch**

- Add healthchecks + restart policies.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-03.md.

### Week 04 - Linux + scripting day-to-day

**Must ship**

- 01-foundations/ notes: permissions, systemd basics, networking basics.
- 5 useful bash scripts (log grep, cleanup, backup, health check, report).

**Stretch**

- Turn one script into a reusable CLI-style tool.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-04.md.

### Week 05 - Kubernetes basics

**Must ship**

- Local cluster (kind/minikube/k3s).
- Deploy a simple app + service.

**Stretch**

- Ingress + DNS notes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-05.md.

### Week 06 - Internship deadline week

**Must ship**

- Portfolio checkpoint: README index linking 4 pillars (even if incomplete).
- CV refresh draft (1 page) focused on DevOps/DevSecOps proof.

**Stretch**

- 2 mock interview stories (STAR format).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-06.md.

### Week 07 - Troubleshooting week

**Must ship**

- 05-kubernetes/troubleshooting.md: pods, logs, events, exec, describe.
- Fix 3 "broken deploy" scenarios.

**Stretch**

- Add readiness/liveness probes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-07.md.

### Week 08 - K8s security basics

**Must ship**

- RBAC demo: least privilege service account.
- Network policy concept doc.

**Stretch**

- Admission control notes / pod security standards.
- Add a Helm chart for the lab app (or a simple nginx app) and document a values file.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-08.md.

### Week 09 - CI baseline

**Must ship**

- .gitlab-ci.yml with stages: lint/test → build → package.
- Artifact retention configured.

**Stretch**

- Pipeline badge in README.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-09.md.

### Week 10 - CI improvements

**Must ship**

- Caching + faster pipeline.
- Clear job naming + logs are readable.

**Stretch**

- Add rules/only/except equivalent (pipeline rules) for branches/MRs.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-10.md.

### Week 11 - Container build in CI

**Must ship**

- Build and publish a container image (GitLab registry or Docker Hub).
- README: how to reproduce locally.

**Stretch**

- Add image tagging strategy (commit SHA + semver).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-11.md.

### Week 12 - CI quality: reliability + failure modes

**Must ship**

- Add a deliberate failing test and show pipeline catches it.
- Document "common CI failures" playbook.

**Stretch**

- Add retry logic where appropriate.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-12.md.

### Week 13 - Secret scanning

**Must ship**

- Add secret detection to pipeline.
- Add one example: detected → fixed → prevented.

**Stretch**

- Add pre-commit hook for secret scanning.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-13.md.

### Week 14 - Dependency scanning

**Must ship**

- Add dependency scanning.
- Document what a CVE is and how I triaged it.

**Stretch**

- Add allowlist/ignore file with justification.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-14.md.

### Week 15 - SAST

**Must ship**

- Add SAST to pipeline.
- Show one finding and remediation.

**Stretch**

- Add MR gating (fail on High severity).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-15.md.

### Week 16 - Container scanning

**Must ship**

- Add container image scanning.
- Add policy: fail on critical/high.

**Stretch**

- Reduce image vulnerabilities by base-image hardening.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-16.md.

### Week 17 - Metrics basics

**Must ship**

- Prometheus + Grafana locally.
- 1 dashboard that shows CPU/mem/requests.

**Stretch**

- Alert rule draft (high error rate).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-17.md.

### Week 18 - Logging basics

**Must ship**

- Centralized logs (Loki or similar) and search queries.
- Document: "metrics vs logs vs traces".

**Stretch**

- Add structured logging note.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-18.md.

### Week 19 - App SLO mindset

**Must ship**

- Define 2 SLOs (latency, error rate).
- Show how I'd monitor them.

**Stretch**

- Add a simple synthetic check.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-19.md.

### Week 20 - Incident drill

**Must ship**

- Simulate outage, write a mini postmortem template.

**Stretch**

- Create a runbook for the demo app.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-20.md.

### Week 21 - Terraform basics

**Must ship**

- Terraform project skeleton + remote state plan (doc).
- First simple resource deployed (prefer Azure student credit).

**Stretch**

- Add make targets or scripts for plan/apply/destroy.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-21.md.

### Week 22 - Networking baseline

**Must ship**

- Create a VNet/VPC + subnets + basic NSG/SG rules.
- Document the topology.

**Stretch**

- Add flow logs / basic logging notes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-22.md.

### Week 23 - Modules + structure

**Must ship**

- Convert repeated patterns into a module.
- Add variables + outputs cleanly.

**Stretch**

- Add environment separation (dev/test).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-23.md.

### Week 24 - Teardown discipline

**Must ship**

- Destroy checklist + cost guardrails doc.
- Verify everything is torn down.

**Stretch**

- Add policy-as-code (basic linting for Terraform).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-24.md.

### Week 25 - Reference architecture 1

**Must ship**

- Markdown architecture: simple web app (compute + DB + cache + CDN).

**Stretch**

- Add cost + security notes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-25.md.

### Week 26 - Reference architecture 2

**Must ship**

- Event-driven architecture (queue/topics + workers).

**Stretch**

- Add failure modes + retries.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-26.md.

### Week 27 - Reference architecture 3

**Must ship**

- Data pipeline architecture (ingest → store → transform).

**Stretch**

- Add governance/permissions notes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-27.md.

### Week 28 - Architecture interview prep

**Must ship**

- 6 tradeoff notes: availability, latency, cost, security, complexity, ops.

**Stretch**

- Record a 5 -7 min explanation (private is fine).

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-28.md.

### Week 29 - Identity

**Must ship**

- Least privilege exercise + role-based access notes.

**Stretch**

- Document break-glass admin strategy.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-29.md.

### Week 30 - Logging/auditing

**Must ship**

- Enable audit logs, export, and interpret 5 events.

**Stretch**

- Create an alert for suspicious sign-in.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-30.md.

### Week 31 - Secrets + key management

**Must ship**

- Store secrets in a proper secret store
- rotate one secret.

**Stretch**

- Add encryption-at-rest and explain.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-31.md.

### Week 32 - Cloud baseline hardening checklist

**Must ship**

- Create a reusable checklist for new projects.

**Stretch**

- Turn checklist into a script that audits basics.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-32.md.

### Week 33 - SBOM + dependency hygiene

**Must ship**

- Generate or document SBOM conceptually
- ensure dependency pinning.

**Stretch**

- Add automated dependency update workflow.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-33.md.

### Week 34 - Build integrity

**Must ship**

- Document provenance and how I prevent tampering in CI.

**Stretch**

- Add signing (or a signing plan) for artifacts.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-34.md.

### Week 35 - Automation scripts v1

**Must ship**

- 3 Python scripts in 10-automation-scripts/ with docs.

**Stretch**

- Add unit tests for scripts.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-35.md.

### Week 36 - Automation scripts v2

**Must ship**

- 3 more scripts (total 6).

**Stretch**

- Add a simple CLI wrapper.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-36.md.

### Week 37 - Optional track week

**Must ship**

- 1 small improvement (docs, refactor, dashboard, or script).

**Stretch**

- Add one more security CI control.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-37.md.

### Week 38 - Optional track week

**Must ship**

- 1 small improvement + weekly notes.

**Stretch**

- Fix one "paper cut" in my toolchain.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-38.md.

### Week 39 - Optional track week

**Must ship**

- Add one interview story (STAR) to docs/.

**Stretch**

- Record a short explanation of my pipeline.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-39.md.

### Week 40 - Optional track week

**Must ship**

- Add one automated check to pipeline or scripts.

**Stretch**

- Add a small monitoring alert.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-40.md.

### Week 41 - Optional track week

**Must ship**

- Networking refresh: TCP/UDP, DNS, TLS, routing basics notes.

**Stretch**

- Packet capture mini-lab (Wireshark) + writeup.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-41.md.

### Week 42 - Optional track week

**Must ship**

- Threat modeling: STRIDE-style for my lab app.

**Stretch**

- Add security headers / WAF notes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-42.md.

### Week 43 - Optional track week

**Must ship**

- Incident response basics: detection → triage → contain → recover notes.

**Stretch**

- Add a runbook for suspicious sign-in.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-43.md.

### Week 44 - Optional track week

**Must ship**

- 2 more automation scripts (total 8).

**Stretch**

- Add tests + linting for scripts.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-44.md.

### Week 45 - Optional track week

**Must ship**

- Portfolio index page: what, why, how to run.

**Stretch**

- Add screenshots/gifs.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-45.md.

### Week 46 - Optional track week

**Must ship**

- CV refresh v2 (DevSecOps-focused) + LinkedIn refresh.

**Stretch**

- 5 targeted job descriptions and keyword alignment notes.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-46.md.

### Week 47 - Optional track week

**Must ship**

- 5 interview Q&As written (CI, Docker, k8s, Terraform, IAM).

**Stretch**

- 1 mock interview recording.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-47.md.

### Week 48 - Optional track week

**Must ship**

- Clean repo: consistent READMEs, instructions, and licensing.

**Stretch**

- Add "lessons learned" doc.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-48.md.

### Week 49 - Optional track week

**Must ship**

- Capstone integration: tie CI + scanning + deploy to k8s (local).

**Stretch**

- Add monitoring and an alert.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-49.md.

### Week 50 - Optional track week

**Must ship**

- Security review: re-run scans, reduce top 5 issues.

**Stretch**

- Add artifact signing plan.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-50.md.

### Week 51 - Optional track week

**Must ship**

- Automation scripts reach 10 total.

**Stretch**

- Bundle scripts into a single documented toolkit.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-51.md.

### Week 52 - Optional track week

**Must ship**

- done / partial / not done

**Stretch**

- Publish a short writeup (blog/LinkedIn) summarizing the journey.

**Proof to capture:** links, screenshots, commands, and a short retro in docs/weekly/week-52.md.
