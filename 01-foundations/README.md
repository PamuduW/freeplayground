# Linux + Scripting Foundations (Week 04)
This module covers Linux day-to-day skills I rely on throughout the rest of this repo: file permissions, systemd service management, and networking basics. The goal is a solid baseline for operating servers, debugging access issues, and inspecting connectivity before moving into heavier automation and platform work.

## Quick reference
### Permissions
```bash
ls -l path                    # long listing shows mode, owner, group
chmod u+x script.sh           # add execute for owner; symbolic change
chmod 644 file.txt            # rw-r--r--: owner read/write, group/other read
chown user:group file.txt     # change owner and group (-R for trees)
```

### systemd
```bash
systemctl status nginx.service    # unit state, recent log lines, cgroup hints
sudo systemctl restart nginx.service
journalctl -u nginx.service -n 50 --no-pager   # last 50 log lines for the unit
```

### Networking
```bash
ip addr show                    # addresses per interface (replaces ifconfig)
ip route show                   # default gateway and routes
ss -tlnp                       # TCP listeners, numeric ports, process info
dig +short example.com A        # quick DNS answer; drop +short for full RR details
```

## Module docs map
- `info/_index.md` - navigation for this module's deep-dive notes.
- `info/permissions.md` - symbolic and numeric modes, `chmod`/`chown`, `umask`, special bits, ACLs, common patterns, permission-denied debugging.
- `info/systemd-basics.md` - unit types, `systemctl`, `journalctl`, unit file anatomy, timers, common failures.
- `info/networking-basics.md` - `ip`, `ss`, DNS tools, HTTP probes with `curl`/`wget`, firewall stacks, resolver and name-service files, reachability checklists.

## Scripts
Reusable scripts for this phase live under `10-automation-scripts/` when I add automation tied to these foundations.
