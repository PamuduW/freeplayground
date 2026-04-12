# FreePlayground Game Plan (12 months)
This repo is my public engineering lab notebook and proof-of-work log.

The goal is consistent growth across DevOps fundamentals, cloud, automation, and security, resulting in a portfolio of practical, reviewable technical work.

## Principles
- WSL-first workflow: projects live in the Linux filesystem and tooling runs inside WSL.
- Quota-based progress: I finish the weekly deliverable, not "work every day".
- Dynamic plan, fixed outcomes: scope can change, outcomes stay the same.
- Slip rule: if work slips, it can roll forward, but not by more than 2 weeks without rebalancing scope.
- Quality baseline: I run `make qa` before push and keep linting/formatting enforced locally via pre-commit.
- Documentation sync baseline: when I change behavior or structure, I update related docs in the same change.
- Technical docs baseline: module technical README files are detailed notes with command/action explanations and troubleshooting points.
- Module docs baseline: each technical module uses a local `info/` folder for focused notes/runbooks instead of putting everything in a single README.

## Weekly Git workflow (branch-per-week)
- I create a new branch for each week: `week/NN-short-theme` (for example: `week/02-docker`).
- I open a Draft merge request to `main` at the start of the week, and push commits to the week branch as work progresses.
- At the end of the week, I merge the MR into `main` using a **merge commit** (so the full week history stays visible on `main`).
- Week branches are kept after merge (not deleted).
- I tag the merge commit with `week-NN` (`make tag-week WEEK=NN`) so each week is easy to locate later.

## Success outcomes (end of 12 months)
By the end of this plan, this repo should demonstrate:
- Strong DevOps fundamentals (Linux, Git, CI/CD, containers, Kubernetes, IaC).
- Solid cloud foundations (AWS + Azure) with cost discipline and teardown habits.
- Real DevSecOps practices (CI security checks, basic threat modeling, IAM hygiene, supply chain awareness).
- Automation mindset (small tools/scripts that remove repetitive work).
- A consistent weekly proof-of-work trail with evidence.

## Weekly cadence
Every week ships:
1. A deliverable (doc, lab, script, pipeline, diagram, or mini-project)
2. Evidence (screenshots, links, outputs)
3. A short retro (what worked, what to improve)

Weekly notes live in:
- `docs/weekly/week-XX.md`
- `docs/info/tree.md` (quick current folder structure snapshot)

Learning notes live in:
- `docs/learn/` (conceptual deep-dives, one file per topic)

Reference docs live in:
- `docs/info/`
- `<module>/info/` for module-specific notes (for example: `02-docker/info/`)

Module placement rules:
- Reusable scripts and helpers live under `10-automation-scripts/`.
- `02-docker/app/` is the Docker/Compose learning artifact — it stays mostly frozen after the Docker phase.
- `11-backend-lab/` is the evolving anchor app used as the target for K8s, CI pipelines, security scanning, and later phases.

Template:
- `docs/info/_template.md`
- `docs/info/linting-formatting-workflow.md` (quality workflow reference)

## Plan document (source of truth)
The detailed 12-month weekly plan lives here:
- `docs/info/FreePlayground_Game_Plan.md`

This `game-plan.md` file is the living index and will be updated if the plan is adjusted.

## Current status
- Logs exist for Week 01, Week 02, Week 03, and Week 04 under `docs/weekly/`.
- Week 04 (Linux + scripting day-to-day) is closing on branch `week/04-linux_+_scripting_day-to-day`.
- Next planned: Week 05 (Internship deadline week), per `docs/info/FreePlayground_Game_Plan.md`.
