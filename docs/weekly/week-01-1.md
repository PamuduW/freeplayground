# Week 01-1 - Linting and formatting baseline add-on
## Goal
Ship a portfolio-grade quality workflow with one command (`make qa`) and CI enforcement using only free/open tools.

## Must ship (definition of done)
- [x] Add pre-commit as the single local runner.
- [x] Add `make hooks` and `make qa` workflow.
- [x] Add GitLab lint job that runs pre-commit for all files.
- [x] Add local tool configs for Ruff, YAML, Markdown, and Prettier.
- [x] Document the workflow in README and info docs.

## Stretch (nice to have)
- [x] Add manual-stage hadolint hook.
- [x] Add Markdown heading style normalization for my preferred format.

## What I did (short log)
- Added a `Makefile` quality workflow: `make hooks` and `make qa`.
- Added `.pre-commit-config.yaml` with Python, Shell, YAML, Markdown, JSON/YAML formatting, and Dockerfile checks.
- Added local configs: `pyproject.toml`, `.yamllint`, `.markdownlint-cli2.yaml`, and `.prettierignore`.
- Added CI `lint` stage/job that runs pre-commit across all files.
- Added `tools/quality/strip_md_heading_blank_lines.py` and wired it into pre-commit.
- Updated docs so the workflow is easy to repeat every week.

## What I learned
- Running auto-fixers first and then re-checking gives a reliable clean-state signal.
- Keeping quality config in repo (not global tooling) makes setup reproducible in WSL and CI.
- Pre-commit can conflict with mixed staged/unstaged edits, so I run `make qa` before staging.

## Notes / commands / snippets
Commands I ran that matter:

```bash
make hooks
make qa
.venv/bin/pre-commit run --all-files --hook-stage manual hadolint
```

## Evidence (links + screenshots)
### Links
- GitHub: <link>
- GitLab: <link>
- Branch: week-02
- MR: <link>
- Pipeline: <link>
- Tag (optional): week-01-1
- Quality guide: docs/info/linting-formatting-workflow.md

### Screenshots
- `docs/weekly/images/week-01/` with add-on filenames (for example: `week-01-1-img-01.png`).

## Retro
### Went well
- One-command quality checks made pre-push validation straightforward.
- Keeping tool configs local removed machine-specific drift.

### Needs improvement
- I should keep commits smaller when hooks auto-format many files at once.

### Next week adjustment (scope can change, outcome stays)
- Keep `make qa` as a required pre-push step and capture evidence in the week log continuously.
