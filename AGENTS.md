# FreePlayground Agent Notes
## What this repo is
This is my proof-of-work lab repo for DevSecOps / Cloud Security learning and homelab experiments.

## Source of truth for the plan
- Weekly plan: `docs/info/FreePlayground_Game_Plan.md`

## Non-negotiables
- Weeks are tracked by number only (Week 01, Week 02, ...). A week starts Monday and ends Sunday. No real dates in weekly logs.
- In repo docs (README, weekly logs), I write in first person (me/my/mine) and avoid second person (you/your).
- I merge into main using merge commits (no squash).
- When repo behavior or structure changes, I update all necessary related docs/files in the same change set (README files, AGENTS.md, workflow docs, and other impacted docs).
- I use `docs/info/tree.md` as a quick structure reference file when planning and reviewing changes.
- I write module technical README files in a detailed technical style with commands, flag/action explanations, and troubleshooting notes.
- Each technical module keeps its own local docs under `<module>/info/` (for example: `02-docker/info/`), and the module README links to those files.
- I keep reusable helper scripts under `10-automation-scripts/`.

## Weekly Git workflow (branch-per-week)
- Each week has its own branch: `week/NN-short-theme` (example: `week/03-docker-compose`).
- A Draft merge request to `main` is opened at the start of the week.
- All week work is committed to the week branch.
- End of week: merge the MR into `main` with a merge commit.
- After merge: tag the merge commit with `make tag-week WEEK=NN` (alias: `make tgw W=NN`).
- Weekly log includes the branch name and MR link under Evidence.

## Where to log work
- Weekly logs live under `docs/weekly/week-XX.md`.
- Weekly evidence images live under `docs/weekly/images/week-XX/` with week-based naming.
- Repo-level reference docs live under `docs/info/`.
- Module-level reference docs live under each module's `info/` folder.

## Temp folder (`temp/`)
- `temp/` is git-ignored and used for throwaway files: scratch notes, learning guides, example images, draft YAML/text/Markdown, or anything I plan to delete later.
- When I ask to create a temporary or throwaway file, always place it in `temp/`.
- Never reference `temp/` files from tracked docs (they can disappear at any time).

## How I want changes made
- Plan first. Before opening files, I list up to 3 files I need and why.
- I use `rg` for discovery and open only relevant file sections.
- I keep diffs small and easy to review.
- I update documentation alongside behavior changes.
- I explicitly mention impacted file paths when changes affect workflows, structure, or runbooks.
- I reference key files where relevant (for example: `docs/info/tree.md` for structure and `docs/info/*.md` for workflows/rules).
- I avoid scanning large binaries (PDFs/images) unless explicitly requested.
- I do not want agents to commit changes when work is done; I review and commit the changes myself after review.

## Definition of done
- Each week ships at least one concrete artifact (code/docs) + `docs/weekly/week-XX.md` + evidence (commands, links, screenshots).
- I provide a minimal diff and the exact commands needed to verify the change, then I stop.

## Codex sanity checks (when I start a session)
- I use `/status` to confirm the workspace root, writable roots, and token usage.
- I use `/debug-config` if expected rules or config do not seem to be applied.
- I use `/compact` after long sessions to keep context lean.
- I check `docs/info/tree.md` for a quick view of the current folder structure before planning larger edits.

## App ownership and backward compatibility
- `02-docker/app/` is the Docker/Compose learning artifact. It stays mostly frozen after the Docker phase (Weeks 02-03). Minor backward-compatible changes are fine, but it should not become the target of K8s manifests, CI pipelines, or security scans in later weeks.
- `11-backend-lab/` is the evolving anchor app. When K8s, CI, and security phases begin, that app is the one that gets Helm charts, pipeline jobs, image scanning, etc.
- Module docs are local to their phase. `02-docker/info/` documents Docker concepts as of Weeks 02-03 and does not need to track changes made in later phases.
- When adding new features to the app (e.g. a new dependency), the change must be backward-compatible: existing standalone Docker commands in older module docs must still work without modification.
- If a code change would break an older module's workflow, either make the change backward-compatible (graceful fallback) or put the new behavior in a separate app/module.

## Teardown discipline (cloud labs)
- After any cloud lab, I verify resources are deleted and cost impact is 0.
- I keep a short teardown checklist in the week log.

## Full repo check
- Last full check commit: `37edf98` (Week 03 close)
- What the check covers: placeholder/unfilled text in docs (`<link>`, `(update with ...)`, `img-YY`, unchecked boxes in completed weeks), missing weekly log links in root README, stale titles/headings, tree.md accuracy, broken internal links, CHANGELOG.md completeness (all weeks represented), game-plan.md current status accuracy, weekly-workflow.md example commands matching actual remote setup, module README week ranges matching content.
- When I ask for a full check, only scan files changed since this commit (`git diff --name-only <hash>..HEAD`). After the check, update this commit hash.
