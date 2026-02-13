# FreePlayground Game Plan (12 months)

This repo is my public engineering lab notebook and proof-of-work log.

The goal is consistent growth across DevOps fundamentals, cloud, automation, and security, resulting in a portfolio I can show confidently in interviews.

## Principles
- WSL-first workflow: projects live in the Linux filesystem and tooling runs inside WSL.
- Quota-based progress: finish the weekly deliverable, not "work every day".
- Dynamic plan, fixed outcomes: scope can change, outcomes stay the same.
- Slip rule: if work slips, it can roll forward, but not by more than 2 weeks without rebalancing scope.

## Weekly Git workflow (branch-per-week)
- I create a new branch for each week: `week/NN-short-theme` (for example: `week/02-docker`).
- I open a Draft merge request to `main` at the start of the week, and push commits to the week branch as work progresses.
- At the end of the week, I merge the MR into `main` using a **merge commit** (so the full week history stays visible on `main`).
- I delete the week branch after merge to keep the branch list clean.
- Optional: I add a lightweight tag `week-NN` on the merge commit so each week is easy to locate later.

## Success outcomes (end of 12 months)
By the end of this plan, this repo should demonstrate:
- Strong DevOps fundamentals (Linux, Git, CI/CD, containers, Kubernetes, IaC).
- Solid cloud foundations (AWS + Azure) with cost discipline and teardown habits.
- Real DevSecOps practices (CI security checks, basic threat modeling, IAM hygiene, supply chain awareness).
- Automation mindset (small tools/scripts that remove repetitive work).
- A consistent weekly proof-of-work trail with evidence.

## Weekly cadence
Every week ships:
1) A deliverable (doc, lab, script, pipeline, diagram, or mini-project)
2) Evidence (screenshots, links, outputs)
3) A short retro (what worked, what to improve)

Weekly notes live in:
- `docs/weekly/week-XX.md`

Template:
- `docs/info/_template.md`

This `game-plan.md` file is the living index and will be updated if the plan is adjusted.

## Current status
- Week 01: repo initialized, CI scaffold created, mirroring enabled, weekly notes started
- Next: Week 02 in branch `week/02-docker`
