# systemd basics
These notes cover how I reason about systemd as PID 1's service manager, inspect and control units, read journals, sketch unit files, and debug failed services.

## What systemd is and why it matters
**systemd** is the init system and service manager on most modern Linux distributions. As **PID 1**, it adopts orphaned processes, reap zombies, and defines boot order through **units**. For day-to-day work, the important parts are: **declarative unit files**, **dependency ordering**, **centralized logging** via journald, and **socket/timer activation** patterns that replace many ad-hoc cron and inetd setups.

Understanding units and `journalctl` saves time when a service "works manually" but fails under systemd (environment, working directory, privileges, timeouts).

## Unit types
| Suffix | Purpose |
|--------|---------|
| `.service` | Long-running daemon, one-shot command, or oneshot during boot — the most common type I touch. |
| `.timer` | Schedules activation of another unit (often a `.service`) — cron-like, with calendar and monotonic specs. |
| `.socket` | Socket activation: systemd listens; service starts on first connection (can replace classic inetd patterns). |
| `.target` | Grouping and synchronization point (e.g. `multi-user.target`, `graphical.target`) — dependency hub, not a process itself. |

Other types exist (`.device`, `.mount`, `.swap`, `.path`, `.slice`, `.scope`); for foundations, services, timers, sockets, and targets cover most scenarios.

## systemctl — core commands
```bash
systemctl status ssh.service
# shows Active state, main PID, cgroup, memory hints, and recent log lines

sudo systemctl start ssh.service
sudo systemctl stop ssh.service
sudo systemctl restart ssh.service
sudo systemctl reload ssh.service
# reload: signal-friendly config refresh when supported (not all units implement it)

sudo systemctl enable ssh.service
# create symlinks so unit starts on boot (WantedBy= in [Install])

sudo systemctl disable ssh.service
# remove those symlinks

systemctl is-active ssh.service
# prints `active` or `inactive` (non-zero exit if inactive — useful in scripts)

systemctl is-enabled ssh.service
# enabled, disabled, static, masked, etc.

systemctl list-units --type=service --state=running
# --type: filter; --state: filter loaded/active/failed

systemctl list-unit-files --type=service
# static/disabled/enabled at install time; shows preset state

systemctl daemon-reload
# required after editing unit files in /etc/systemd/system (or drops)
```

**Masking** (strong disable — unit cannot start until unmasked):

```bash
sudo systemctl mask avahi-daemon.service
# symlinks to /dev/null in unit load path

sudo systemctl unmask avahi-daemon.service
```

**Useful flags:**

- `--user` — user session manager instead of system (`systemctl --user ...`).
- `-H host` — remote host over SSH (if configured).

## journalctl — logs
systemd captures stdout/stderr and syslog from services into the **journal**.

```bash
journalctl -b
# -b: current boot only (default is all persistent journal)

journalctl -b -1
# previous boot

journalctl -u nginx.service
# -u: filter by unit

journalctl -u nginx.service -n 100 --no-pager
# -n: last N lines; --no-pager: dump for piping

journalctl -u nginx.service --since "1 hour ago" --until "10 minutes ago"
# time window (many natural language forms accepted)

journalctl -p err
# -p: priority at least err (emerg alert crit err warning notice info debug)

journalctl -f
# follow new entries (like tail -f)

journalctl _COMM=sshd
# filter by syslog identifier / metadata field
```

**Persistence:** On some systems the journal is volatile until `/var/log/journal` exists and `Storage=persistent` (or similar) is set in `journald.conf`.

## Writing a simple .service unit
Unit files usually live in `/etc/systemd/system/` for local overrides. **Drop-ins** in `something.service.d/override.conf` are preferred over copying vendor units wholesale.

Minimal anatomy:

```ini
[Unit]
Description=My demo API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/myapp --config /etc/myapp/config.toml
WorkingDirectory=/var/lib/myapp
User=myapp
Group=myapp
Restart=on-failure
Environment=APP_ENV=production

[Install]
WantedBy=multi-user.target
```

**Section notes:**

- **[Unit]** — human metadata, ordering (`After`, `Before`), weak/strong deps (`Wants`, `Requires`).
- **[Service]** — `ExecStart`, `ExecStop`, `Restart=` policy, `Type=` (`simple`, `forking`, `oneshot`, `notify`), security hardening directives (`NoNewPrivileges=`, `ProtectSystem=`, etc.) on newer units.
- **[Install]** — `WantedBy=` / `RequiredBy=` defines what `systemctl enable` links into (typical target: `multi-user.target`).

After editing:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now myapp.service
# --now: start immediately
```

## Timer units — cron replacement sketch
A **timer** activates another unit on a calendar or elapsed schedule.

`backup.service` (oneshot):

```ini
[Unit]
Description=Daily backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

`backup.timer`:

```ini
[Unit]
Description=Run backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl enable --now backup.timer
systemctl list-timers
```

**`Persistent=true`** catches up if the machine was off when the timer would have fired.

## Troubleshooting
**Service won't start**

1. `systemctl status unit` — exit codes, "Main process exited", signal kills.
2. `journalctl -u unit -b --no-pager` — full story from first failure line.
3. `systemctl cat unit` — effective unit with drop-ins merged.
4. Run `ExecStart` manually as the **same user** with the same env; compare `Environment=` and `WorkingDirectory=`.
5. Check `Type=` mismatch (daemon that forks may need `Type=forking` and `PIDFile=`).

**Dependency failures**

- `systemctl list-dependencies unit` — what it pulls in.
- `systemctl show -p Requires -p Wants -p After unit` — parsed properties.

**Logs missing or empty**

- Service might log only to files under `/var/log` — check unit documentation.
- `StandardOutput=null` or `syslog` in unit — adjust or use `journalctl` with metadata filters.
- User services: `journalctl --user -u unit`.

**Reload vs restart**

- Config changes that only need SIGHUP: `systemctl reload` if implemented.
- Otherwise `restart`; for D-Bus activated units, sometimes `systemctl try-restart`.

Keeping unit changes in **drop-ins** makes upgrades safer than editing `/lib/systemd/system` vendor files directly.
