# Linting and formatting workflow
This repo uses `pre-commit` as the single quality runner for local commits and CI.

## Why I set it up
- I want one reliable command to auto-fix and verify quality before push.
- I want consistent formatting and linting across Python, Shell, YAML, Dockerfiles, and Markdown.
- I want CI to enforce the same baseline as local runs.

## Core commands
```bash
make hooks
make qa
make hadolint
make qa-full
```

## What each command does
- `make hooks`: installs the git pre-commit hook and prepares hook environments.
- `make qa`: refreshes `docs/info/tree.md` via `tools/update-tree.sh`, runs all hooks across all files, allows auto-fixes on pass 1, then re-runs on pass 2 to confirm clean.
- `make hado`: runs the manual-stage hadolint hook across Dockerfiles.
- `make qaf`: runs `make qa` and then `make hadolint`.

## What runs automatically
- On commit: pre-commit runs the configured hooks for changed files.
- On CI (`lint` job): pre-commit runs against all files.
- Manual only: Dockerfile linting with hadolint.

## Manual hadolint run
```bash
.venv/bin/pre-commit run --all-files --hook-stage manual hadolint
```

I normally use `make hadolint` as the short command.

## Hook coverage
- Repo hygiene: trailing whitespace, EOF fixer, merge conflict check, YAML validity, large file check, private key detection.
- Python: `ruff` lint with `--fix`, then `ruff format`.
- Shell: `shfmt` and `shellcheck`.
- YAML: `yamllint` with local `.yamllint` rules.
- Markdown: `markdownlint-cli2` plus a local heading-spacing normalizer.
- JSON/YAML formatting: `prettier`.

## Where files live
- Root config files stay in repo root for simple tool discovery:
  - `.pre-commit-config.yaml`
  - `.yamllint`
  - `.markdownlint-cli2.yaml`
  - `.prettierignore`
- Custom quality scripts live under `tools/quality/`.

## Notes about folder layout
It is possible to move more config files into a subfolder, but that adds extra flags and wrapper wiring for local hooks, CI, and editor integrations. I keep the main dotfiles in root to keep setup simple and predictable.

## Commit workflow I follow
```bash
make qa
git add -A
git commit -m "<message>"
```

This order avoids pre-commit stash conflicts from mixed staged and unstaged edits.

## Partial commit workflow I follow
If I want to commit only part of my work, I use this flow so pre-commit does not fail on stash/apply conflicts:

```bash
# stage only what I want to commit
git add -p

# stash everything else but keep staged changes in place
git stash push --keep-index --include-untracked -m "partial-commit-temp"

# commit staged changes only
git commit -m "<message>"

# bring back remaining work
git stash pop
```

If hooks auto-fix files during commit, I re-stage those files and run commit again.
