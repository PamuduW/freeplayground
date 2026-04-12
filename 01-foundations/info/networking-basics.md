# Linux networking fundamentals
These notes cover how I inspect addresses and routes, list sockets, debug DNS, probe HTTP, compare firewall stacks, and interpret core resolver files. The focus is everyday CLI tooling on modern Linux.

## ip — replacing ifconfig and route
The **ip** suite (`iproute2`) is the modern interface for links, addresses, neighbors, and routing.

**Addresses:**

```bash
ip addr show
# all interfaces; shorthand: ip a

ip -4 addr show dev eth0
# -4: IPv4 only; dev: single interface

ip -brief addr
# terse table; useful in scripts
```

**Links (layer 2 state):**

```bash
ip link show
# UP/DOWN, MTU, MAC

sudo ip link set dev eth0 up
# administrative UP

ip -s link show dev eth0
# -s: statistics (RX/TX counters)
```

**Routing:**

```bash
ip route show
# full table; default via ...

ip route get 203.0.113.50
# which path the kernel would choose (interface, src, gateway)

ip -6 route show
# IPv6 table
```

**Flags I use often:**

- `-4` / `-6` — address family filter.
- `brief` — compact output.
- `-s` — statistics on `ip -s link` or `ip -s addr`.

Legacy `ifconfig` and `route` may still exist but can hide information or behave inconsistently; I default to `ip`.

## ss — replacing netstat
**ss** reads socket information from the kernel (via `netlink`), faster than scanning `/proc` manually.

**Listening TCP sockets with processes:**

```bash
ss -tlnp
# -t: TCP; -l: listening; -n: numeric ports; -p: show process (needs suitable privileges)
```

**Filter by port:**

```bash
ss -tlnp sport = :443
# sport: source port filter syntax

ss -tunlp
# -u: include UDP; common combo for "what is open"
```

**Connection states (TCP):**

```bash
ss -tan state established
# -a: all (listening + non-listening); state filter
```

**UDP** is stateless; `UNCONN` vs `ESTAB` semantics differ from TCP. For UDP listeners, I still use `-ulnp`.

**vs netstat:** `ss` is the maintained tool; `netstat` is often a symlink or optional package.

## DNS tools: dig, nslookup, host
**dig** — most flexible; script-friendly.

```bash
dig example.com
# A record query using resolver defaults; shows QUESTION, ANSWER, AUTHORITY, ADDITIONAL

dig +short example.com A
# +short: answer only — good for quick checks

dig @1.1.1.1 example.com MX
# @server: query a specific resolver

dig +trace example.com
# iterative trace from roots — useful for delegation debugging

dig -x 203.0.113.10
# reverse (PTR) lookup
```

Reading a typical **ANSWER SECTION**: owner name, TTL, class (`IN`), type (`A`, `AAAA`, `CNAME`, …), RDATA.

**nslookup** — interactive or non-interactive; behavior has historically varied between implementations. I use it when already in an old runbook, but prefer `dig` for precision.

```bash
nslookup example.com 8.8.8.8
# server as second arg
```

**host** — concise summary output for quick human checks.

```bash
host example.com
host -t MX example.com
# -t: explicit query type
```

## curl and wget — HTTP(S) testing
**curl** — fine-grained control, great for APIs and reproducing headers.

```bash
curl -v https://example.com/
# -v: verbose (TLS handshake, headers) — first step when something "hangs"

curl -I https://example.com/
# -I: HEAD request (headers only)

curl -o out.html -L https://example.com/page
# -o: output file; -L: follow redirects

curl -sS https://api.example.com/health
# -s: silent progress; -S: show errors even when silent (recommended pair)

curl --resolve example.com:443:127.0.0.1 https://example.com/
# test vhost/SNI against local without editing /etc/hosts
```

**wget** — strong at recursive fetch and simple downloads.

```bash
wget -S -O - https://example.com/
# -S: print server response headers; -O -: write to stdout

wget --spider https://example.com/robots.txt
# HEAD-like existence check without storing body
```

I pick **curl** when I need verbs, custom headers, or TLS details; **wget** for mirror-style pulls or simple scripts on minimal systems.

## Firewall basics: iptables, nftables, ufw
**iptables** — classic IPv4/IPv6 packet filter (Netfilter). Tables (`filter`, `nat`, `mangle`), chains (`INPUT`, `FORWARD`, `OUTPUT`), rules with matches and targets (`ACCEPT`, `DROP`, `REJECT`). Still common in docs and older scripts.

**nftables** — modern replacement with one engine, expressive rule syntax, atomic updates. Many distros now generate nftables rulesets even if the front-end is higher level.

**ufw** — **Uncomplicated Firewall**, an abstraction over iptables or nftables depending on distro. Good for simple host policy.

```bash
sudo ufw status verbose
# show rules and default policies

sudo ufw allow 22/tcp
# insert allow rule for SSH

sudo ufw enable
# turn on (ensure SSH allowed first to avoid lockout)

sudo ufw deny 80/tcp
# explicit deny (order matters relative to allows)
```

**Comparison snapshot:** raw **iptables/nftables** for precision and automation; **ufw** for quick host hardening; cloud **security groups** still sit outside the VM and must agree with host rules (double filtering causes "port closed" confusion).

## /etc/hosts, /etc/resolv.conf, /etc/nsswitch.conf
**/etc/hosts** — static name-to-IP mappings. Checked according to **nsswitch** order. Highest priority for local overrides and lab shortcuts. I keep it minimal on servers to avoid drift.

**/etc/resolv.conf** — resolver configuration: `nameserver`, `search`, `options`. On desktop/laptop with **systemd-resolved** or **NetworkManager**, this file may be a symlink to a generated stub; editing it directly sometimes has no lasting effect. I check `resolvectl status` or NM tools when `resolv.conf` looks auto-managed.

**/etc/nsswitch.conf** — **Name Service Switch** order, notably the `hosts:` line:

```text
hosts: files dns myhostname
```

`files` before `dns` means `/etc/hosts` wins for matches. Changing this order has security and performance implications (I rarely change it without a reason).

## Troubleshooting: can't reach a host
I use a layered checklist:

1. **DNS** — Does the name resolve? `dig +short host.example` vs expected IP. Wrong answer → resolver, search list, or authoritative DNS issue.
2. **Route** — `ip route get <ip>` — is there a path? Missing default route or wrong interface breaks everything non-local.
3. **Local firewall** — `ss -tlnp` on server (service listening? correct address `0.0.0.0` vs `127.0.0.1`?). `sudo ufw status` or inspect nftables/iptables counters.
4. **Remote firewall / security groups** — cloud SGs, corporate ACLs, ISP blocking (common for port 25).
5. **Service health** — process up, bound to expected port, TLS certs valid (curl `-v` shows cert errors clearly).
6. **Path MTU / asymmetric routing** — rare; `ping` works but large TCP hangs — `tracepath` can hint.

**Loopback vs all interfaces:** If a service binds `127.0.0.1:8080`, it is not reachable from other hosts until it binds `0.0.0.0` or a specific LAN IP — `ss -tlnp` shows the bind address explicitly.

This stack — **name → route → local filter → remote filter → application** — keeps debugging ordered instead of random poking.
