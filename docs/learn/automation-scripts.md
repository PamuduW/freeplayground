# Automation scripts — what I learned (Week 04)
## What this folder is for
`10-automation-scripts/` is where I keep small reusable CLI tools that solve repeatable day-to-day problems. In Week 04 I used Bash for all five scripts, kept the interface consistent, and treated each script like a tiny command-line program instead of a one-off snippet.

Shared conventions across the Week 04 scripts:
- `#!/usr/bin/env bash` shebang so the script runs with Bash from the active environment
- `set -euo pipefail` so failures stop early instead of getting hidden
- small helper functions like `die()` and `info()` to keep output predictable
- explicit usage text with `-h` or `--help`
- positional arguments only where they make sense

The goal was not "write shell for the sake of shell." The goal was to build commands I can run again later without rethinking the flags every time.

## The five scripts at a glance
| Script | Problem it solves | Main inputs | Main outputs |
| --- | --- | --- | --- |
| `log-grep.sh` | Search logs quickly, optionally by date range | pattern, log root, date filters | matching lines or per-file counts |
| `cleanup.sh` | Preview and remove old files | age threshold, target directories | dry-run summary or deletion summary |
| `backup.sh` | Create timestamped `tar.gz` backups | source directory, output directory, excludes, retention | archive file + verification stats |
| `health-check.sh` | Run simple host health checks | selected checks, thresholds, services list | OK/WARN/CRIT output or JSON |
| `report.sh` | Capture a system snapshot | text vs markdown, optional output path | report to stdout or file |

## How I should think about temp folders
`temp/` in this repo is a git-ignored scratch area. It is safe to create and safe to delete.

Important behavior difference:
- `backup.sh` and `report.sh` create missing output directories automatically because they write new output files.
- `cleanup.sh` does **not** create missing target directories. That is intentional. If I pass a directory to clean, the directory should already exist.
- `health-check.sh` and `log-grep.sh` do not need temp storage at all.

So if `temp/` is missing and I run:

```bash
10-automation-scripts/report.sh -f markdown -o temp/sysreport.md
10-automation-scripts/backup.sh -o temp 01-foundations/
```

those scripts recreate the needed output path themselves. But if I run:

```bash
10-automation-scripts/cleanup.sh -n -d 7 temp
```

and `temp/` does not exist, `cleanup.sh` will just warn that the path is missing and skip it.

## `log-grep.sh`
### What it does
`log-grep.sh` searches readable regular files under a directory and runs `grep` against them. The default search root is `/var/log`, which makes it useful for quick local log inspection, but I can also point it at any test folder.

### Syntax
```bash
10-automation-scripts/log-grep.sh [-d DIR] [-a AFTER_DATE] [-b BEFORE_DATE] [-i] [-c] PATTERN
```

### Flags
- `-d DIR`
  Search under `DIR` instead of `/var/log`.
- `-a AFTER_DATE`
  Only include files modified on or after the supplied GNU `date` string.
- `-b BEFORE_DATE`
  Only include files modified on or before the supplied GNU `date` string.
- `-i`
  Case-insensitive matching.
- `-c`
  Count-only mode, similar to `grep -c`.

### Required input
- `PATTERN`
  This is required. Without it the script exits with an error.

### Examples
```bash
10-automation-scripts/log-grep.sh -i "error"
10-automation-scripts/log-grep.sh -d /var/log -a "2026-04-01" "docker"
10-automation-scripts/log-grep.sh -d temp/week04-test/logs -c "ERROR"
```

### What the date filters really mean
The script filters by **file modification time**, not by timestamps inside the log lines. That matters:
- if a log file contains old entries but the file itself was modified today, it still matches a current date filter
- if I need line-level time filtering, I would need a different script that parses the log content itself

### Exit behavior
- `0` if at least one match is found
- `1` if no matches are found
- `1` on some usage errors as well, because `die()` exits with code 1

### Good troubleshooting checks
- "not a directory" means the `-d` path is wrong
- "invalid AFTER_DATE" or "invalid BEFORE_DATE" means GNU `date` could not parse the string
- "No readable files found" usually means the directory is empty, unreadable, or filtered out by the date options

## `cleanup.sh`
### What it does
`cleanup.sh` finds regular files older than `N` days and either previews them or deletes them. It is deliberately conservative:
- it only targets regular files
- it stays on one filesystem per target because it uses `find ... -xdev`
- it always prints a dry-run summary before deletion

### Syntax
```bash
10-automation-scripts/cleanup.sh [-n] [-v] [-d DAYS] [DIR...]
```

### Flags
- `-n`
  Dry run only. No deletion happens.
- `-v`
  Verbose mode. Print each candidate file.
- `-d DAYS`
  Age threshold in days. Default is `30`.

### Default targets
If I pass no directories, it checks:
- `/tmp`
- `~/.cache`
- `/var/tmp`

### Examples
```bash
10-automation-scripts/cleanup.sh -n
10-automation-scripts/cleanup.sh -n -v -d 7 temp
10-automation-scripts/cleanup.sh -v -d 30 ~/.cache
```

### Important behavior
`cleanup.sh` does not create directories. It expects its target paths to already exist. If a target is missing, it prints a warning and skips it.

That behavior is safer than auto-creating a directory because a "cleanup" command should not silently create empty folders and pretend it cleaned something.

### How the deletion flow works
Without `-n`, the script does this:
1. collect candidates
2. print a dry-run summary
3. delete files
4. run a post-delete summary

So even a real delete run still shows what it found before removing anything.

### Good troubleshooting checks
- if it prints `skip (not a directory)`, the target path does not exist
- if it finds nothing, check the `-d DAYS` value and the file modification times
- if it cannot delete a file, I should check file ownership and permissions

## `backup.sh`
### What it does
`backup.sh` creates a timestamped `tar.gz` archive from a source directory, verifies the archive, prints archive stats, and can prune older backups.

### Syntax
```bash
10-automation-scripts/backup.sh [-o OUTPUT_DIR] [-e EXCLUDE_PATTERN] [-k N] SOURCE_DIR
```

### Flags
- `-o OUTPUT_DIR`
  Directory where the archive should be written. Default is the current directory.
- `-e EXCLUDE_PATTERN`
  Repeatable `tar --exclude` pattern.
- `-k N`
  Keep only the newest `N` matching backups in the output directory. `0` disables pruning.

### Required input
- `SOURCE_DIR`
  The directory to archive.

### Output behavior
`backup.sh` creates the output directory automatically if it does not exist. That is the right behavior for an archive-writing tool.

Archive filename format:

```text
backup_<dirname>_YYYYMMDD_HHMMSS.tar.gz
```

### Examples
```bash
10-automation-scripts/backup.sh 01-foundations/
10-automation-scripts/backup.sh -o temp 01-foundations/
10-automation-scripts/backup.sh -o temp/backups -e '*.log' -e '__pycache__' -k 3 01-foundations/
```

### What the verification step proves
After archive creation, the script runs:

```bash
tar -tzf "$ARCHIVE_PATH"
```

That does not prove my backup is logically complete, but it *does* prove the generated archive is readable and not obviously corrupted.

### Retention pruning
If I use `-k 3`, the script:
- finds backup files matching the same source name pattern
- sorts them by modification time
- keeps the newest three
- removes older ones

This keeps the folder from filling up with dozens of nearly identical archives.

### Good troubleshooting checks
- "not a directory" means `SOURCE_DIR` is wrong
- "cannot create output directory" usually means permission trouble or a bad path
- if pruning removes files unexpectedly, check which source folder name the archive pattern is based on

## `health-check.sh`
### What it does
`health-check.sh` runs a small set of host checks and reports each one as `OK`, `WARN`, or `CRIT`.

The available checks are:
- `disk`
- `memory`
- `cpu`
- `services`
- `network`
- `all`

### Syntax
```bash
10-automation-scripts/health-check.sh [OPTIONS] [CHECKS...]
```

### Flags
- `--no-color`
  Disable ANSI colors.
- `--json`
  Emit JSON lines instead of text.
- `--warn-disk PCT`
  Disk warning threshold. Default is `80`.
- `--warn-mem PCT`
  Memory warning threshold. Default is `80`.
- `--services LIST`
  Comma-separated service names for the service check. Default is `sshd,docker`.

### Examples
```bash
10-automation-scripts/health-check.sh --services docker
10-automation-scripts/health-check.sh disk memory --warn-disk 90 --warn-mem 90 --services docker
10-automation-scripts/health-check.sh --json --services docker
```

### Why it may look broken on my machine when it is not
By default, the service check monitors `sshd,docker`. On a workstation where `sshd` is intentionally inactive, the script reports:

```text
[CRIT] services: sshd=inactive; docker=active;
```

That is expected behavior, not a parsing bug. If I only care about Docker for my current lab, I should run:

```bash
10-automation-scripts/health-check.sh --services docker
```

### Exit codes
- `0` if there are no critical checks
- `1` if at least one check is critical
- `2` for usage or parse errors

### Good troubleshooting checks
- if `services` fails unexpectedly, run `systemctl is-active <service>`
- if `network` warns, verify the default route with `ip route show default`
- if `disk` or `memory` warnings seem too noisy, tune `--warn-disk` or `--warn-mem`

## `report.sh`
### What it does
`report.sh` generates a host summary report in either plain text or Markdown.

Sections included:
- hostname / OS
- uptime
- CPU
- memory
- disk usage
- network interfaces
- top processes
- recent logins
- installed package count

### Syntax
```bash
10-automation-scripts/report.sh [-o FILE] [-f FORMAT]
```

### Flags
- `-o FILE`
  Write the report to a file instead of stdout.
- `-f FORMAT`
  Output format: `text` or `markdown`.

### Examples
```bash
10-automation-scripts/report.sh
10-automation-scripts/report.sh -f markdown
10-automation-scripts/report.sh -f markdown -o temp/sysreport.md
```

### Output behavior
`report.sh` creates missing parent directories for the output file automatically. So if `temp/` does not exist, this still works:

```bash
10-automation-scripts/report.sh -f markdown -o temp/sysreport.md
```

### What this report is good for
- attaching a quick system snapshot to a weekly log
- capturing baseline host state before making changes
- producing Markdown output I can paste into docs or a merge request note

### Good troubleshooting checks
- "unsupported format" means the `-f` value is not `text` or `markdown`
- "could not create output directory" means the parent path is invalid or not writable
- if a section looks sparse, the underlying system tool may not exist on that machine

## Why these scripts matter beyond Week 04
This week was not only about "learning Bash syntax." It was about learning how to make small tools behave like real software:
- parse arguments carefully
- fail loudly on bad input
- print useful help text
- separate preview from destructive actions
- make output predictable enough for later automation

That same thinking shows up again in CI pipelines, deployment scripts, security checks, and cloud automation. These five scripts are small, but the habits behind them scale.
