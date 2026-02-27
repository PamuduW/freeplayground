# FreePlayground Agent Notes
## What this repo is
This is my proof-of-work lab repo for DevSecOps / Cloud Security learning and homelab experiments.

## Source of truth for the plan
- Weekly plan: `docs/info/FreePlayground_Game_Plan_v3.md`

## Non-negotiables
- Weeks are tracked by number only (Week 01, Week 02, ...). A week starts Monday and ends Sunday. No real dates in weekly logs.
- In repo docs (README, weekly logs), I write in first person (me/my/mine) and avoid second person (you/your).
- I merge into main using merge commits (no squash).

## Weekly Git workflow (branch-per-week)
- Each week has its own branch: `week/NN-short-theme` (example: `week/03-docker-compose`).
- A Draft merge request to `main` is opened at the start of the week.
- All week work is committed to the week branch.
- End of week: merge the MR into `main` with a merge commit.
- After merge: delete the week branch.
- Optional: tag `week-NN` on the merge commit.
- Weekly log includes the branch name and MR link under Evidence.

## Where to log work
- Weekly logs live under `docs/weekly/week-XX.md`.
- Weekly evidence images live under `docs/weekly/images/week-XX/` with week-based naming.

## How I want changes made
- Plan first. Before opening files, I list up to 3 files I need and why.
- I use `rg` for discovery and open only relevant file sections.
- I keep diffs small and easy to review.
- I update documentation alongside behavior changes.
- I avoid scanning large binaries (PDFs/images) unless explicitly requested.
- I do not want agents to commit changes when work is done; I review and commit the changes myself after review.

## Definition of done
- Each week ships at least one concrete artifact (code/docs) + `docs/weekly/week-XX.md` + evidence (commands, links, screenshots).
- I provide a minimal diff and the exact commands needed to verify the change, then I stop.

## Codex sanity checks (when I start a session)
- I use `/status` to confirm the workspace root, writable roots, and token usage.
- I use `/debug-config` if expected rules or config do not seem to be applied.
- I use `/compact` after long sessions to keep context lean.

## Teardown discipline (cloud labs)
- After any cloud lab, I verify resources are deleted and cost impact is 0.
- I keep a short teardown checklist in the week log.
