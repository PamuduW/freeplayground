# Week 01 — Kickoff & setup

## Goal
Set up FreePlayground as a long-term engineering growth repo with a working CI pipeline, clean structure, and repeatable weekly shipping format.

## Must ship (definition of done)
- [x] Create repo + folder skeleton (local WSL + remote)
- [x] Add weekly notes structure (`docs/weekly/`) and Week 01 log
- [x] Add GitLab CI scaffold and confirm pipeline runs on push
- [x] Add GitLab pipeline badge to README
- [x] Rename default branch from `master` → `main` (and push updates)
- [x] Add `CHANGELOG.md`
- [x] Add `docs/game-plan.md`
- [x] Set up GitLab → GitHub mirroring (push mirror)

## Stretch (nice to have)
- [ ] Cost guardrails checked (AWS + Azure) (Budgets/alerts + teardown discipline)
- [ ] Add repo description/topics + pin the repo on GitHub/GitLab

## What I did (short log)
- Initialized the repo inside WSL and set Git identity.
- Added both remotes (GitLab + GitHub) and pushed the initial commits.
- Created a minimal GitLab CI pipeline and verified a green run.
- Added pipeline status badge to the README.
- Renamed default branch to `main`.
- Set up GitLab push-mirroring to GitHub and verified sync.

## What I learned
- Task lists render properly with `- [ ]` and `- [x]` checkbox syntax.
- GitLab pipeline badges are just URLs tied to `project_path` + `default_branch`.
- Mirroring fails fast if auth is wrong (token/username issues show up clearly in logs).

## Notes / commands / snippets
```bash
# Git identity (one-time)
git config --global user.email "pamuduwijesingha2k20@gmail.com"
git config --global user.name  "Pamudu Wijesingha"

# Remotes
git remote add gitlab git@gitlab.com:PamuduW/freeplayground.git
git remote add github git@github.com:PamuduW/freeplayground.git
git remote -v

# Push
git push -u gitlab main
git push -u github main
```

## Evidence (links + screenshots)
- Links:
  - GitHub: https://github.com/PamuduW/freeplayground
  - GitLab: https://gitlab.com/PamuduW/freeplayground
  - Pipelines: https://gitlab.com/PamuduW/freeplayground/-/pipelines

- Screenshots:
   
  ![GitHub README badge and repo](images/week-01-img-01.png)
  ![GitLab mirroring success](images/week-01-img-02.png)

## Retro
- Went well:
  - Shipping the scaffold fast made the repo feel “real” immediately.
  - CI + badge makes progress visible (and keeps you honest).

- Needs improvement:
  - Cost guardrails still pending (must be done before any serious cloud labs).

- Next week adjustment (scope can change, outcome stays):
  - Finish AWS + Azure cost guardrails first, then start Week 02 labs.
