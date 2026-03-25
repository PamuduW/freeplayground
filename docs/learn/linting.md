# Linting and formatting — how it all works
This is a deep-dive into the linting/formatting setup in this repo. It explains every piece: why a Python venv exists, what pre-commit is, what happens when I type `git commit`, what each hook does, and what every config file controls.

## What linting and formatting even are
**Linting** = static analysis. A linter reads code and flags problems without running it. Examples: unused imports, undefined variables, inconsistent indentation, missing EOF newline, YAML syntax errors. Linters catch bugs and style violations early.

**Formatting** = auto-rewriting code to match a style. A formatter changes whitespace, quote styles, line breaks, etc. Examples: Prettier rewrites YAML/JSON to consistent indentation, `ruff format` rewrites Python to a standard style. The key difference from linting: a formatter doesn't just complain — it rewrites the file.

Some tools do both (ruff can lint AND format). Some only lint (shellcheck). Some only format (prettier, shfmt).

## The big picture: what runs and when
```text
make hooks (run once)
    └─ creates .venv, installs pre-commit, wires git hook

git commit (every commit)
    └─ git sees .git/hooks/pre-commit exists
        └─ runs pre-commit framework
            └─ pre-commit reads .pre-commit-config.yaml
                └─ runs each hook on staged files
                    └─ if ANY hook fails → commit is blocked
                    └─ if ALL hooks pass → commit proceeds

make qa (manual, any time)
    └─ runs pre-commit on ALL files (not just staged)
    └─ does it twice: pass 1 allows auto-fixes, pass 2 confirms clean
```

## Why a Python virtual environment exists
### What is a venv?
A Python virtual environment (`.venv/`) is an isolated Python installation. It has its own `pip`, its own `site-packages`, and its own binaries. Anything installed inside `.venv/` does not touch the system Python.

### Why this repo needs one
`pre-commit` is a Python package. To run it, I need to install it somewhere. Options:
1. Install globally (`pip install pre-commit`) — pollutes system Python, may conflict with other projects
2. Install in a venv — isolated, reproducible, safe to delete and recreate

This repo uses option 2. The venv exists solely to host the `pre-commit` CLI tool. It has nothing to do with the FastAPI app in `02-docker/`.

### What lives inside .venv/
```text
.venv/
├── bin/
│   ├── python          ← isolated Python interpreter
│   ├── pip             ← isolated pip
│   └── pre-commit      ← the tool we actually need
├── lib/
│   └── python3.12/
│       └── site-packages/
│           ├── pre_commit/   ← pre-commit source code
│           ├── virtualenv/   ← dependency of pre-commit
│           ├── pyyaml/       ← dependency of pre-commit
│           └── ...           ← other dependencies
└── pyvenv.cfg          ← venv metadata
```

The venv is git-ignored (`.gitignore` has `.venv/`). Every developer recreates it locally with `make hooks`.

## What `make hooks` does — step by step
Looking at the Makefile:
```makefile
PYTHON ?= python3
VENV ?= .venv
PRE_COMMIT ?= $(VENV)/bin/pre-commit
PRE_COMMIT_HOME ?= $(CURDIR)/.cache/pre-commit

$(PRE_COMMIT):
	$(PYTHON) -m venv $(VENV)
	$(VENV)/bin/python -m pip install pre-commit

hooks: $(PRE_COMMIT)
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) install --install-hooks --hook-type pre-commit
```

### Step 1: `python3 -m venv .venv`
Creates the virtual environment directory. `-m venv` tells Python to run the built-in `venv` module. After this, `.venv/bin/python` and `.venv/bin/pip` exist.

### Step 2: `.venv/bin/python -m pip install pre-commit`
Uses the venv's own pip to install the `pre-commit` package (and its dependencies) into the venv. After this, `.venv/bin/pre-commit` exists.

Dependencies installed alongside pre-commit (visible in lint.log):
- `cfgv` — config file validator (pre-commit uses it to validate `.pre-commit-config.yaml`)
- `identify` — file type identification (how pre-commit knows a file is Python vs Shell vs YAML)
- `nodeenv` — creates isolated Node.js environments (needed for hooks like prettier and markdownlint)
- `pyyaml` — YAML parser (pre-commit reads YAML configs)
- `virtualenv` — creates isolated environments for hook dependencies

### Step 3: `mkdir -p .cache/pre-commit`
Creates the cache directory where pre-commit stores installed hook environments. `PRE_COMMIT_HOME` is set to this path so all hook caches stay inside the repo (instead of the default `~/.cache/pre-commit`).

### Step 4: `pre-commit install --install-hooks --hook-type pre-commit`
This does two things:
1. **`install --hook-type pre-commit`**: writes a shell script to `.git/hooks/pre-commit`. This is the git hook — the bridge between `git commit` and the pre-commit framework. After this, every `git commit` triggers pre-commit automatically.
2. **`--install-hooks`**: pre-reads `.pre-commit-config.yaml` and installs every hook's environment NOW (instead of waiting until first use). This is why the lint.log shows lines like:
   ```text
   [INFO] Installing environment for https://github.com/astral-sh/ruff-pre-commit.
   [INFO] Once installed this environment will be reused.
   [INFO] This may take a few minutes...
   ```
   Each hook repo gets its own isolated environment under `.cache/pre-commit/`. For example, ruff gets a Python env with the ruff binary, markdownlint gets a Node.js env, etc.

## What happens when I type `git commit`
Here is the exact sequence:

### 1. Git checks for hooks
Git looks at `.git/hooks/pre-commit`. If the file exists and is executable, git runs it BEFORE creating the commit.

### 2. The hook script runs pre-commit
The script at `.git/hooks/pre-commit` was written by `pre-commit install`. It calls `.venv/bin/pre-commit run` with the list of staged files.

### 3. Pre-commit reads `.pre-commit-config.yaml`
It parses the config to find which hooks to run.

### 4. Pre-commit filters files
Each hook has file type filters (Python, Shell, YAML, Markdown, etc.). Pre-commit uses the `identify` library to determine each staged file's type and only passes relevant files to each hook.

### 5. Hooks run in order
Each hook defined in `.pre-commit-config.yaml` runs top to bottom. For each hook:
- If the hook **passes** (exit code 0): green "Passed", move to next hook
- If the hook **fails** (exit code non-zero): red "Failed", and:
  - If it only reported problems (like shellcheck): I fix manually
  - If it auto-fixed files (like trailing-whitespace, ruff --fix, prettier --write): the files on disk are now modified but the staged version is stale

### 6. Commit proceeds or is blocked
- **All hooks pass**: git creates the commit.
- **Any hook fails**: git aborts the commit. I need to fix issues, re-stage (`git add`), and commit again.
- **Auto-fix happened**: the hook returns exit code 1 (fail) even though it fixed the files. This is intentional — it blocks the commit so I can review the auto-fixes, `git add` the fixed files, and commit again.

### Important: hooks only run on staged files
When triggered by `git commit`, pre-commit only checks files that are in the staging area (`git add`). Unstaged changes are temporarily stashed away during the hook run. This is why `make qa` (which runs `--all-files`) exists as a separate manual check.

## Every hook explained
### Repo: pre-commit/pre-commit-hooks (general hygiene)
**trailing-whitespace**
- What: removes trailing spaces/tabs at the end of lines
- Why: trailing whitespace causes noisy diffs and is never intentional
- Auto-fixes: yes, rewrites files in place

**end-of-file-fixer**
- What: ensures every file ends with exactly one newline character
- Why: POSIX standard. Some tools (cat, diff) behave unexpectedly without a trailing newline
- Auto-fixes: yes

**check-merge-conflict**
- What: looks for leftover merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) in files
- Why: accidentally committing conflict markers breaks code
- Auto-fixes: no, I fix manually

**check-yaml**
- What: validates YAML syntax (parses every `.yml`/`.yaml` file)
- Why: catches typos like bad indentation or duplicate keys before they break CI or Docker Compose
- Auto-fixes: no

**check-added-large-files**
- What: rejects files larger than 1024 KB (`--maxkb=1024`)
- Why: large binaries bloat the git repo permanently (git stores every version)
- Auto-fixes: no, I must remove the file or add it to `.gitignore`

**detect-private-key**
- What: scans for patterns that look like private keys (RSA, DSA, EC, PGP headers)
- Why: committing a private key is a security incident
- Auto-fixes: no, I must remove the key

### Repo: astral-sh/ruff-pre-commit (Python)
**ruff** (linter)
- What: an extremely fast Python linter. Checks for errors, style issues, import ordering, etc.
- Config: `pyproject.toml` under `[tool.ruff]` and `[tool.ruff.lint]`
- The `--fix` arg means ruff auto-fixes what it can (like removing unused imports, sorting imports)
- Rule sets enabled: `E` (pycodestyle errors), `F` (pyflakes), `W` (pycodestyle warnings), `I` (isort/import sorting), `UP` (pyupgrade/modernize syntax), `B` (bugbear/common bugs)
- Auto-fixes: yes (for fixable rules)

**ruff-format** (formatter)
- What: reformats Python code (like Black, but faster). Enforces consistent quotes, indentation, line length
- Config: `pyproject.toml` under `[tool.ruff.format]`
- Settings: double quotes, spaces (not tabs), LF line endings, 100 char line length
- Auto-fixes: yes, rewrites files

### Repo: scop/pre-commit-shfmt (Shell formatting)
**shfmt**
- What: formats shell scripts (bash/sh). Normalizes indentation, spacing around operators, case statement alignment
- Auto-fixes: yes, rewrites files
- Example: if I wrote `if [  "$x" = "y"  ];then` it becomes `if [ "$x" = "y" ]; then`

### Repo: koalaman/shellcheck-precommit (Shell linting)
**shellcheck**
- What: static analysis for shell scripts. Finds bugs like unquoted variables, missing `set -e`, useless use of cat, etc.
- Auto-fixes: no, I fix manually. Shellcheck gives error codes (SC2086, SC2046, etc.) with explanations
- Example: `rm $file` triggers SC2086 because `$file` should be quoted as `"$file"` to handle spaces

### Repo: adrienverge/yamllint (YAML linting)
**yamllint**
- What: lints YAML files for syntax and style (indentation, trailing spaces, key duplication, line length, etc.)
- Config: `.yamllint` file in repo root
- Current settings:
  - `extends: default` — start with yamllint's default rules
  - `ignore: .git/, docs/weekly/images/` — skip these paths
  - `line-length: disable` — allow long lines (default limit is 80 which is too strict for URLs/commands)
  - `document-start: disable` — don't require `---` at the top of every YAML file
  - `comments-indentation: disable` — allow comments at any indentation level
- Auto-fixes: no

### Repo: DavidAnson/markdownlint-cli2 (Markdown linting)
**markdownlint-cli2**
- What: lints Markdown files for formatting issues (heading style, list indentation, blank lines, HTML usage, etc.)
- Config: `.markdownlint-cli2.yaml`
- `pass_filenames: false` — don't pass individual filenames; instead markdownlint-cli2 uses the `globs` key in its config to find files itself
- Current disabled rules:
  - `MD013: false` — line length (disabled, same reason as yamllint)
  - `MD022: false` — headings should be surrounded by blank lines (conflicts with the custom strip script)
  - `MD031: false` — fenced code blocks should be surrounded by blank lines
  - `MD032: false` — lists should be surrounded by blank lines
  - `MD024: siblings_only: true` — duplicate headings allowed if they are not siblings (e.g., same heading in different sections is OK)
  - `MD026: false` — trailing punctuation in headings
  - `MD033: false` — inline HTML (sometimes needed)
  - `MD034: false` — bare URLs without angle brackets
  - `MD036: false` — emphasis used instead of a heading
  - `MD058: false` — tables should be surrounded by blank lines
- Auto-fixes: no

### Local hook: prettier (JSON/YAML formatting)
**prettier**
- What: an opinionated code formatter. In this repo, it only runs on `.yml`, `.yaml`, and `.json` files (the `files:` regex limits scope)
- `--write`: rewrite files in place (auto-fix mode)
- `language: node` tells pre-commit this hook needs Node.js. Pre-commit uses `nodeenv` to create an isolated Node environment and installs `prettier@3.3.3` into it
- Auto-fixes: yes
- Example: reformats YAML indentation, normalizes JSON key quoting/spacing

### Local hook: strip-md-heading-blank-lines (custom)
**strip markdown heading blank lines**
- What: a custom Python script (`10-automation-scripts/quality/strip_md_heading_blank_lines.py`) that removes accidental blank lines immediately after Markdown headings
- Why: my writing style puts content right after a heading with no blank line. This script enforces that consistently.
- `language: system` — runs using the system Python (not inside a venv). This means it uses whatever `python3` is on `PATH`
- `files: \.md$` — only runs on Markdown files
- How it works internally: reads each `.md` file, finds headings (lines starting with `#`), removes blank lines between the heading and the next content line, writes back if changed. Also collapses duplicate adjacent headings.
- Auto-fixes: yes (rewrites files, returns exit code 1 so the commit is blocked for review)

### Local hook: hadolint (Dockerfile linting, manual only)
**hadolint**
- What: lints Dockerfiles against best practices (e.g., pin versions in `apt-get install`, avoid `COPY .`, use `--no-install-recommends`)
- `language: docker_image` — pre-commit pulls and runs the `hadolint/hadolint:v2.12.0` Docker image. No local install needed, but Docker must be running.
- `stages: [manual]` — this hook does NOT run on `git commit`. It only runs when explicitly invoked with `--hook-stage manual` (via `make hadolint`)
- Why manual: hadolint requires Docker to be running. Not every commit touches Dockerfiles. Running it on every commit adds latency and may fail if Docker is stopped.
- Auto-fixes: no

## Config files explained
### `.pre-commit-config.yaml`
The central config. Defines which hooks run, from which repos, at which versions.

```yaml
default_stages: [pre-commit]
```
Only run hooks at the `pre-commit` stage by default (i.e., on `git commit`). Other possible stages: `pre-push`, `commit-msg`, `manual`.

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
```
Each `repo` block points to a git repository containing hook definitions. `rev` pins the exact version (git tag). This means everyone on the team gets the same hook version. `hooks` lists which hooks from that repo to enable.

```yaml
  - repo: local
    hooks:
      - id: prettier
        language: node
        entry: prettier
        additional_dependencies:
          - prettier@3.3.3
```
`repo: local` means the hook is defined inline (not from an external repo). `language: node` tells pre-commit to create a Node.js environment. `entry: prettier` is the command to run. `additional_dependencies` lists npm packages to install in that Node environment.

### `pyproject.toml`
Ruff's configuration. Not all tools use this — only tools that read `pyproject.toml` (ruff, black, mypy, pytest, etc.).

```toml
[tool.ruff]
line-length = 100         # max characters per line before ruff complains
target-version = "py311"  # assume Python 3.11+ syntax is available

[tool.ruff.lint]
select = ["E", "F", "W", "I", "UP", "B"]
# E  = pycodestyle errors (bad whitespace, missing whitespace, etc.)
# F  = pyflakes (undefined names, unused imports, redefined unused, etc.)
# W  = pycodestyle warnings (deprecated features, whitespace issues)
# I  = isort (import sorting and grouping)
# UP = pyupgrade (modernize syntax: dict() → {}, old-style formatting → f-strings)
# B  = flake8-bugbear (common bugs: mutable default arguments, assert False, etc.)

[tool.ruff.format]
quote-style = "double"    # use "double quotes" not 'single quotes'
indent-style = "space"    # spaces, not tabs
line-ending = "lf"        # Unix line endings (\n), not Windows (\r\n)
```

### `.yamllint`
yamllint's configuration.

```yaml
extends: default          # start from yamllint's default ruleset
ignore: |
  .git/
  docs/weekly/images/     # skip binary/image directories
rules:
  line-length: disable    # don't enforce line length (URLs and commands get long)
  document-start: disable # don't require --- at the top of YAML files
  comments-indentation: disable  # allow comments at any indentation
```

### `.markdownlint-cli2.yaml`
markdownlint configuration.

```yaml
globs:
  - "**/*.md"             # lint all .md files recursively
ignores:
  - ".cache/**"           # skip pre-commit cache
  - ".venv/**"            # skip Python venv
  - "node_modules/**"     # skip Node modules
  - "docs/weekly/images/**"  # skip image directories
  - "docs/info/tree.md"   # skip generated tree file
config:
  default: true           # enable all rules by default, then disable specific ones below
  MD013: false            # line length — disabled
  MD022: false            # blank lines around headings — conflicts with strip script
  # ... (rest of disabled rules documented in the hook section above)
```

### `.prettierignore`
Tells Prettier which files to skip.

```text
*.png                     # binary files — Prettier can't format these
*.jpg
# ...
.git/                     # never format git internals
node_modules/
.cache/
docs/weekly/images/**     # binary evidence screenshots
docs/info/tree.md         # generated file
```

### `.editorconfig`
Not a linting config — this tells code editors (VS Code, JetBrains, vim) how to format files as I type.

```ini
root = true               # stop looking for .editorconfig files in parent directories

[*]                        # defaults for all files
charset = utf-8
end_of_line = lf           # Unix line endings
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2            # 2-space indent by default

[*.md]
trim_trailing_whitespace = false  # Markdown uses trailing spaces for line breaks

[*.py]
indent_size = 4            # Python convention is 4 spaces

[Makefile]
indent_style = tab         # Makefiles require tabs (not spaces) for recipes
```

This ensures my editor produces files that already match what the linters expect, reducing auto-fix noise.

## The two-pass `make qa` strategy
Looking at the Makefile:
```makefile
qa: $(PRE_COMMIT) refresh-tree
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files || true
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files
```

**Pass 1** (`|| true`): runs all hooks on ALL files. If auto-fixing hooks modify files, the command exits non-zero, but `|| true` swallows the error so the Makefile continues.

**Pass 2** (no `|| true`): runs again. If everything is clean, all hooks pass. If something still fails, the Makefile stops with an error — meaning there is a real issue I need to fix manually.

Why two passes: some hooks auto-fix on first run (trailing-whitespace, prettier, ruff). After fixing, the files are clean. The second pass confirms that. If the second pass still fails, I know the issue is not auto-fixable.

## `make qa` vs `git commit` hooks
| Aspect | `git commit` | `make qa` |
| --- | --- | --- |
| Triggered by | every commit (automatic) | manual command |
| Files checked | only staged files | ALL files in repo |
| Purpose | catch issues before they enter git history | full repo health check |
| Auto-fix behavior | fixes files, blocks commit, I re-stage and commit again | two-pass: fix then verify |
| hadolint | NOT included (manual stage) | NOT included (use `make qa-full`) |

## What `make qa-full` adds
```makefile
qa-full: qa hadolint

hadolint: $(PRE_COMMIT)
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files --hook-stage manual hadolint
```

`make qa-full` runs `make qa` (all standard hooks) and then `make hadolint` (Dockerfile linting via Docker). The `--hook-stage manual` flag tells pre-commit to include hooks tagged with `stages: [manual]`, which are skipped during normal runs.

## Where hook environments live
```text
.cache/pre-commit/
├── repo1abc123/          ← cloned pre-commit-hooks repo + its venv
├── repo2def456/          ← cloned ruff-pre-commit repo + its binary
├── repo3ghi789/          ← cloned shellcheck repo + its binary
├── node_env_xyz/         ← Node.js env for prettier/markdownlint
└── ...
```

Each hook repo gets its own isolated environment. `PRE_COMMIT_HOME` controls where these live. This repo sets it to `.cache/pre-commit/` (inside the repo, git-ignored) instead of the default `~/.cache/pre-commit` (user home). This keeps everything self-contained.

## Recreating everything from scratch
If `.venv/` or `.cache/` get corrupted or deleted:
```bash
rm -rf .venv .cache/pre-commit
make hooks
```
This recreates the venv, reinstalls pre-commit, and re-downloads all hook environments. The repo code is unaffected.

## The complete flow (end to end)
### First time setup
```text
make hooks
  → python3 -m venv .venv                          # create isolated Python env
  → .venv/bin/pip install pre-commit                # install pre-commit into it
  → .venv/bin/pre-commit install --install-hooks    # wire git hook + download all hook envs
```

### Every commit
```text
git add -A
git commit -m "my message"
  → git runs .git/hooks/pre-commit
    → .venv/bin/pre-commit run (on staged files)
      → trailing-whitespace ........... Passed
      → end-of-file-fixer ............. Passed
      → check-merge-conflict .......... Passed
      → check-yaml .................... Passed
      → check-added-large-files ....... Passed
      → detect-private-key ............ Passed
      → ruff .......................... Passed
      → ruff-format ................... Passed
      → shfmt ......................... Passed
      → shellcheck .................... Passed
      → yamllint ...................... Passed
      → markdownlint-cli2 ............ Passed
      → prettier ...................... Passed
      → strip markdown heading blank .. Passed
    ✓ all passed → commit created
```

### If a hook auto-fixes
```text
git add -A
git commit -m "my message"
  → prettier ......................... Failed
    (prettier rewrote a .yaml file)
  → commit BLOCKED

# the file on disk is now fixed, but git still has the old version staged
git add -A              # re-stage the auto-fixed file
git commit -m "my message"   # hooks run again, this time all pass
  → ✓ commit created
```

### Before pushing / opening MR
```text
make qa        # full repo check + two-pass auto-fix verify
make qa-full   # same + hadolint on Dockerfiles
git push
```
