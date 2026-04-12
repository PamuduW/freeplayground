# Linting and formatting workflow
This repo uses `pre-commit` as the single local quality runner before I commit and push.

## Why I set it up
- I want one reliable command to auto-fix and verify quality before push.
- I want consistent formatting and linting across Python, Shell, YAML, Dockerfiles, and Markdown.
- I want linting and formatting to stay local, while CI focuses on CI/CD flow.

## Core commands
```bash
make hooks
make qa
make hadolint
make qa-full
```

## Local prerequisites
- `python3` for the repo-local `.venv` and `pre-commit`
- `node` and `npm` on `PATH` for the Node-based hooks (`markdownlint-cli2` and `prettier`)

## What each command does
- `make hooks`: checks that `node` and `npm` are available, installs the git pre-commit hook, and prepares hook environments.
- `make qa`: checks that `node` and `npm` are available, refreshes `docs/info/tree.md` via `10-automation-scripts/update-tree.sh`, runs all hooks across all files, allows auto-fixes on pass 1, then re-runs on pass 2 to confirm clean.
- `make hadolint`: runs the manual-stage hadolint hook across Dockerfiles.
- `make qa-full`: runs `make qa` and then `make hadolint`.

`make hooks` ends with a short success message because `pre-commit install --install-hooks` itself does not print a final "done" banner when it succeeds.

## What runs automatically
- On commit: pre-commit runs the configured hooks for changed files.
- Manual only: Dockerfile linting with hadolint.

## CI/CD pipeline scope
- Current CI pipeline is a minimal verify baseline and does not include package/deploy jobs yet.
- Package/deploy work is planned in later CI-focused weeks in `docs/info/FreePlayground_Game_Plan.md`.
- Linting and formatting are enforced locally by `make qa` and commit hooks.

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

Node-based hooks are configured to use the system-installed `node`/`npm` instead of asking pre-commit to download a separate Node runtime.

## Where files live
- Root config files stay in repo root for simple tool discovery:
  - `.pre-commit-config.yaml`
  - `.yamllint`
  - `.markdownlint-cli2.yaml`
  - `.prettierignore`
- Custom quality scripts live under `10-automation-scripts/quality/`.

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
