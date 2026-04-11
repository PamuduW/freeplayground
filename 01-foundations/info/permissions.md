# Linux file permissions
These notes cover how I read and change POSIX permissions on Linux, when special bits and ACLs matter, and how I debug "permission denied" without guessing.

## Symbolic vs numeric (octal) notation
Each file has a mode for **user** (owner), **group**, and **others** (everyone else). Each class gets **read (r)**, **write (w)**, and **execute (x)**.

**Symbolic** form shows letters and optional modifiers:

```bash
ls -l /etc/passwd
# leading '-' = regular file; next 9 chars = rwx for user, group, others
```

**Numeric (octal)** encodes the same three bits per class as one digit 0–7:

| Bit value | Permission |
|-----------|------------|
| 4 | read |
| 2 | write |
| 1 | execute |

Digits are ordered **user, group, others**. Examples:

- `7` = 4+2+1 = `rwx`
- `6` = 4+2 = `rw-`
- `5` = 4+1 = `r-x`
- `4` = `r--`
- `0` = `---`

So `644` means `rw-r--r--`, and `755` means `rwxr-xr-x`.

**Special bits** add a fourth leading digit in four-digit octal (see below): setuid `4`, setgid `2`, sticky `1` (e.g. `4755`).

```bash
stat -c '%a %n' /bin/su
# %a: octal mode as ls would show (often 4 digits if special bits set)
```

## chmod — change mode
```bash
chmod u+x script.sh
# u: user (owner); +: add; x: execute

chmod go-w shared.txt
# g: group, o: others; -: remove write

chmod a=rX public_dir
# a: all (ugo); =: set exactly; X: execute only if directory or already executable for someone

chmod -R u+rwX,go-rwx private_dir
# -R: recurse; combines symbolic specs with comma separation
```

Numeric examples:

```bash
chmod 600 ~/.ssh/id_rsa
# owner read/write only — typical for private keys

chmod 755 ~/bin/myapp
# owner rwx; group and others read+execute — common for small binaries/scripts in $PATH

chmod --reference=ref.txt target.txt
# copy mode from ref.txt (GNU chmod)
```

**Useful flags:**

- `-R` — recurse into directories (careful: easy to overexpose trees).
- `-v` — verbose (shows each change; GNU).
- `-c` — like `-v` but only report when a change was made (GNU).

## chown — change owner (and often group)
```bash
sudo chown alice:developers report.txt
# user:group

sudo chown alice report.txt
# owner only; group unchanged on most systems

sudo chown :developers report.txt
# group only (leading colon)

sudo chown -R alice:developers /srv/app
# -R: recurse
```

**Flags:**

- `-R` — recurse (mandatory caution on system paths).
- `--reference=FILE` — set owner and group to match `FILE` (GNU).

## chgrp — change group
```bash
chgrp developers shared.log
# often requires membership in `developers` unless running as root

sudo chgrp -R www-data /var/www/html
# -R: recurse
```

On systems where I own the file, `chgrp` is enough when only the group must change.

## umask
**umask** is a bitmask **subtracted** from the default mode when creating files and directories (exactly how depends on the application; traditionally files start without execute, directories with execute). It answers: "what permission bits should **not** be granted by default for new items?"

Check current shell umask:

```bash
umask
# prints octal, e.g. 0022

umask -S
# symbolic form, e.g. u=rwx,g=rx,o=rx
```

Set for the current shell session:

```bash
umask 027
# common restrictive choice: group rx, others nothing on new dirs; files lose corresponding bits
```

Persisting umask is usually done in `~/.bashrc`, `~/.profile`, or PAM/user session config — the default on many distros is `0022` (group/others keep read for files created as 644-like defaults) or `0002` on some desktops (shared group write).

**Troubleshooting:** If new files are always "too open" or "too closed", I check `umask` first, then the creating process (language runtime, `sudo`, etc.), because `sudo` may reset the environment.

## Special bits: setuid, setgid, sticky
Displayed in `ls -l` in the **execute** slot:

- **setuid** (`s` in user execute position, e.g. `-rwsr-xr-x`): process runs with **file owner's** EUID (common for `/bin/su`, `/usr/bin/passwd` so unprivileged users can perform controlled privileged actions).
- **setgid** (`s` in group execute): for executables, EGID becomes file's group; for directories, **new files inherit the directory's group** (useful for shared team dirs).
- **sticky** (`t` in others execute, e.g. `/tmp` as `drwxrwxrwt`): only owner (and root) may unlink/rename files inside that directory — prevents users from deleting each other's files in world-writable dirs.

Set numerically (fourth digit) or symbolically:

```bash
chmod u+s /path/to/binary    # setuid
chmod g+s /path/to/dir       # setgid on directory
chmod +t /path/to/tmpdir     # sticky

chmod 4755 binary            # setuid + 755
chmod 2750 teamdir           # setgid + 750
chmod 1777 /tmp              # sticky + 777 (illustrative)
```

**Security note:** setuid on custom binaries is risky; I avoid it unless there is a clear, audited need.

## ACLs — getfacl, setfacl
**POSIX ACLs** extend owner/group/others with per-user and per-group entries and **default ACLs** on directories (inheritance for new children).

```bash
getfacl /srv/shared/project
# dump ACL text including base POSIX mode mapped to ACL entries

setfacl -m u:bob:r-x /srv/shared/project
# -m: modify; grant user bob read+execute

setfacl -m d:g:devs:rwx /srv/shared/project
# d: default ACL for new files/dirs underneath

setfacl -b /srv/shared/project
# -b: remove all ACL entries (base mode remains)
```

**When ACLs help:** multiple groups or users need different access than a single owning group allows; inheritance on a shared tree without resorting to world-readable paths. **When I skip ACLs:** simple owner/group/others is enough and portability to minimal systems matters.

**Flags:**

- `-R` — recurse (setfacl).
- `-x entry` — remove one ACL entry.

If `ls -l` shows a `+` after the mode (`-rw-rw----+`), ACLs are present.

## Common permission patterns
| Mode | Meaning | Typical use |
|------|---------|-------------|
| `600` | `rw-------` | SSH private keys, secret files |
| `640` | `rw-r-----` | config readable by a service group |
| `644` | `rw-r--r--` | public static files, docs |
| `660` | `rw-rw----` | group-shared files (with matching group) |
| `700` | `rwx------` | private directories (`~/.ssh`) |
| `750` | `rwxr-x---` | app dirs readable by group |
| `755` | `rwxr-xr-x` | executables, command scripts, web cgi dirs (legacy) |
| `770` | `rwxrwx---` | collaborative dirs with setgid + shared group |

Directories **need execute** to traverse (`cd`, path resolution); `r` without `x` on a directory allows listing names in some cases but not descent — a common confusion.

## Troubleshooting: "permission denied" checklist
1. **Which path failed?** Distinguish file vs parent directory; missing `--x` on a parent blocks access even if the target is `777`.
2. **Who am I?** `id` — UID, GID, supplemental groups. A new group membership requires a new login/session.
3. **Ownership and mode:** `ls -l` and `namei -l /long/path` (shows each path component).
4. **SELinux/AppArmor:** `getenforce`, `ausearch`, or `aa-status` on hardened systems — DAC can look correct yet MAC still denies.
5. **Filesystem mount options:** `findmnt -o TARGET,OPTIONS` — `noexec`, `nosuid`, `ro`, or NFS roots explain surprises.
6. **ACLs:** `getfacl` when `+` appears in `ls -l`.
7. **Immutable flags (advanced):** `lsattr`, `chattr` — rare but blocks writes despite `chmod`.

Working backward from the syscall perspective helps: open for read needs read on file; execute needs execute on file and traverse on each directory in the path.
