# Week 04 - Linux + Scripting Day-to-Day
## Goal
Ship foundational Linux notes (permissions, systemd, networking) and 5 reusable bash scripts covering common day-to-day tasks.

## Must ship (definition of done)
- [x] `01-foundations/` module: permissions, systemd basics, networking basics
- [x] 5 useful bash scripts in `10-automation-scripts/` (log-grep, cleanup, backup, health-check, report)

## Stretch (nice to have)
- [x] Turn `health-check.sh` into a reusable CLI-style tool with `--help`, flags, colored output, JSON mode, and modular checks

## What I did (short log)
- Created `01-foundations/` module with README and three deep-dive reference docs: `permissions.md` (chmod/chown/umask/special bits/ACLs), `systemd-basics.md` (unit types, systemctl, journalctl, unit file anatomy, timers), and `networking-basics.md` (ip/ss/DNS tools/curl/firewall/resolver config).
- Wrote 5 bash scripts following the repo's existing conventions (`set -euo pipefail`, `die()`/`info()` helpers, proper usage text):
  - `log-grep.sh` — search log files by pattern with optional date-range filtering
  - `cleanup.sh` — remove old temp files/caches with dry-run mode and size summary
  - `backup.sh` — timestamped tar.gz with integrity check and retention rotation
  - `health-check.sh` — modular system health checks (disk/mem/cpu/services/network) with CLI flags, thresholds, colored output, and JSON mode
  - `report.sh` — system summary generator in text or markdown format
- All scripts pass `bash -n` syntax validation.

## What I learned
- `umask` is a subtractive mask, not a direct permission setter — default file creation mode (usually `0666`) minus `umask` gives the actual permissions.
- `setgid` on a directory forces new files to inherit the directory's group, which solves the classic shared-project-folder problem.
- `systemctl is-active` returns a plain string on stdout and a non-zero exit code when the service is not running — useful for scripting without parsing `status` output.
- `ss -tlnp` is the modern replacement for `netstat -tlnp` and gives the same info with better performance.
- `df -P` (POSIX output) avoids line wrapping on long mount paths, making it safe to parse in scripts.

## Notes / commands / snippets
Gotchas when rerunning the scripts:

- Use `temp/`, not `/temp`.
- `health-check.sh` defaults to `sshd,docker`, so on my machine I should pass `--services docker` unless I explicitly want to check `sshd`.

Commands I ran that matter:

```bash
# Quick health check
10-automation-scripts/health-check.sh --services docker
10-automation-scripts/health-check.sh disk memory --warn-disk 90 --services docker
10-automation-scripts/health-check.sh --json --services docker

# System report in markdown
10-automation-scripts/report.sh -f markdown -o temp/sysreport.md

# Backup a directory
10-automation-scripts/backup.sh -o temp 01-foundations/

# Dry-run cleanup
10-automation-scripts/cleanup.sh -n -d 7 temp

# Search logs
10-automation-scripts/log-grep.sh -i "error"
```

## Evidence (links + screenshots)
### Links
- GitHub: https://github.com/PamuduW/freeplayground
- GitLab: https://gitlab.com/PamuduW/freeplayground
- Branch: `week/04-linux_+_scripting_day-to-day`
- MR (branch-filtered view): https://gitlab.com/PamuduW/freeplayground/-/merge_requests?scope=all&state=opened&search=week%2F04-linux_%2B_scripting_day-to-day
- Pipeline (branch-filtered view): https://gitlab.com/PamuduW/freeplayground/-/pipelines?ref=week%2F04-linux_%2B_scripting_day-to-day
- Tag (optional): week-04

### Screenshots
No screenshots are committed for Week 04 yet. If I want visual evidence in-repo before merge, I should add them under `docs/weekly/images/week-04/`.

## Retro
### Went well
- Module structure mirrors `02-docker/` cleanly — README + info/ subdirectory pattern is working well.
- `health-check.sh` came together as a solid CLI tool with proper flag parsing, color support, and JSON output — good stretch goal.
- All five scripts follow the same conventions (shebang, strict mode, helpers, usage), making the codebase consistent.

### Needs improvement
- The foundation notes are reference-only — no hands-on lab exercises yet. Could add a `labs/` subfolder with small guided exercises in a future pass.
- Scripts are not tested with a formal test framework (e.g., bats-core) — adding that would increase confidence.

### Next week adjustment (scope can change, outcome stays)
- Week 05 starts Kubernetes basics (local cluster, deploy an app + service).
