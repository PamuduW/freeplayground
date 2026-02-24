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
- End of week: merge MR into `main` with a merge commit.
- After merge: delete the week branch.
- Optional: tag `week-NN` on the merge commit.
- Weekly log includes the branch name and MR link under Evidence.

## Where to log work

- Weekly logs live under `docs/weekly/week-XX.md`.
- Weekly evidence images live under `docs/weekly/images/week-XX/` with week-based naming.

## How I want changes made

- Plan first. Before opening files, list up to 3 files you need and why.
- Use `rg` for discovery; open only relevant file sections.
- Keep diffs small and easy to review.
- Update documentation alongside behavior changes.
- Avoid scanning large binaries (PDFs/images) unless explicitly requested.

## Definition of done

- Each week ships at least one concrete artifact (code/docs) + `docs/weekly/week-XX.md` + evidence (commands, links, screenshots).
- Provide a minimal diff and the exact commands needed to verify the change, then stop.

## Codex sanity checks (when I start a session)

- Use `/status` to confirm the workspace root, writable roots, and token usage.
- Use `/debug-config` if expected rules or config do not seem to be applied.
- Use `/compact` after long sessions to keep context lean.
