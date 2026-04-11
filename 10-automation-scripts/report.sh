#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------
die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() { echo "$*"; }

usage() {
  cat <<'EOF'
Usage: report.sh [-o FILE] [-f FORMAT]

Generate a system summary report.

  -o FILE    Write report to FILE instead of stdout
  -f FORMAT  text (default) or markdown

Sections: hostname/OS, uptime, CPU, memory, disk, network interfaces,
top processes, recent logins, installed package count (best-effort).
EOF
}

# --- arguments -------------------------------------------------------------
OUT_FILE=""
FORMAT="text"

while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -o)
    [ $# -ge 2 ] || die "-o requires a path"
    OUT_FILE="$2"
    shift 2
    ;;
  -f)
    [ $# -ge 2 ] || die "-f requires a format"
    FORMAT="$2"
    shift 2
    ;;
  -*)
    die "unknown option: $1 (try --help)"
    ;;
  *)
    die "unexpected argument: $1"
    ;;
  esac
done

case "$FORMAT" in
text | markdown) ;;
*) die "unsupported format: $FORMAT (use text or markdown)" ;;
esac

TS=$(date -Iseconds 2>/dev/null || date)

section_text() {
  local title="$1"
  info ""
  info "=== ${title} ==="
}

section_md() {
  local title="$1"
  info ""
  info "## ${title}"
  info ""
}

hostname_os_text() {
  section_text "Hostname / OS"
  info "Hostname: $(hostname -f 2>/dev/null || hostname)"
  if [ -r /etc/os-release ]; then
    info "$(grep -E '^(NAME|VERSION)=' /etc/os-release | sed 's/^/  /')"
  else
    info "OS: (no /etc/os-release)"
  fi
}

hostname_os_md() {
  section_md "Hostname / OS"
  info "- **Hostname:** \`$(hostname -f 2>/dev/null || hostname)\`"
  if [ -r /etc/os-release ]; then
    info ""
    info '```'
    grep -E '^(NAME|VERSION)=' /etc/os-release || true
    info '```'
  else
    info "_/etc/os-release not available_"
  fi
}

uptime_sec_text() {
  section_text "Uptime"
  uptime -p 2>/dev/null || uptime
}

uptime_sec_md() {
  section_md "Uptime"
  info '```'
  uptime -p 2>/dev/null || uptime
  info '```'
}

cpu_text() {
  section_text "CPU"
  if [ -r /proc/cpuinfo ]; then
    info "Model: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | xargs || true)"
    info "Cores (nproc): $(nproc 2>/dev/null || echo '?')"
  else
    info "(no /proc/cpuinfo)"
  fi
}

cpu_md() {
  section_md "CPU"
  info "- **Cores:** $(nproc 2>/dev/null || echo '?')"
  info ""
  info '```'
  grep -m1 'model name' /proc/cpuinfo 2>/dev/null || info "(no cpuinfo)"
  info '```'
}

mem_text() {
  section_text "Memory"
  free -h 2>/dev/null || head -n 5 /proc/meminfo
}

mem_md() {
  section_md "Memory"
  info '```'
  free -h 2>/dev/null || head -n 5 /proc/meminfo
  info '```'
}

disk_text() {
  section_text "Disk usage"
  df -h -x tmpfs -x devtmpfs 2>/dev/null || df -h
}

disk_md() {
  section_md "Disk usage"
  info '```'
  df -h -x tmpfs -x devtmpfs 2>/dev/null || df -h
  info '```'
}

net_text() {
  section_text "Network interfaces"
  ip -br addr 2>/dev/null || ifconfig -a 2>/dev/null || info "(no ip/ifconfig output)"
}

net_md() {
  section_md "Network interfaces"
  info '```'
  ip -br addr 2>/dev/null || ifconfig -a 2>/dev/null || echo "(no ip/ifconfig output)"
  info '```'
}

topproc_text() {
  section_text "Top processes (by CPU)"
  ps aux --sort=-%cpu 2>/dev/null | head -n 11 || ps aux | head -n 11
}

topproc_md() {
  section_md "Top processes (by CPU)"
  info '```'
  { ps aux --sort=-%cpu 2>/dev/null || ps aux; } | head -n 11
  info '```'
}

logins_text() {
  section_text "Recent logins"
  last -n 15 2>/dev/null || last | head -n 15 || info "(last not available)"
}

logins_md() {
  section_md "Recent logins"
  info '```'
  last -n 15 2>/dev/null || last | head -n 15 || echo "(last not available)"
  info '```'
}

pkg_count_text() {
  section_text "Installed packages (approximate)"
  local n="?"
  if command -v dpkg >/dev/null 2>&1; then
    n=$(dpkg -l 2>/dev/null | grep -c '^ii' || echo "?")
    info "dpkg (ii lines): $n"
  elif command -v rpm >/dev/null 2>&1; then
    n=$(rpm -qa 2>/dev/null | wc -l)
    info "rpm -qa count: $n"
  else
    info "Neither dpkg nor rpm found."
  fi
}

pkg_count_md() {
  section_md "Installed packages (approximate)"
  local n="?"
  if command -v dpkg >/dev/null 2>&1; then
    n=$(dpkg -l 2>/dev/null | grep -c '^ii' || echo "?")
    info "- **dpkg** (installed): $n"
  elif command -v rpm >/dev/null 2>&1; then
    n=$(rpm -qa 2>/dev/null | wc -l)
    info "- **rpm** packages: $n"
  else
    info "_Neither dpkg nor rpm found._"
  fi
}

run_report() {
  if [ "$FORMAT" = markdown ]; then
    info "# System report"
    info ""
    info "_Generated: ${TS}_"
    hostname_os_md
    uptime_sec_md
    cpu_md
    mem_md
    disk_md
    net_md
    topproc_md
    logins_md
    pkg_count_md
  else
    info "System report (generated: ${TS})"
    hostname_os_text
    uptime_sec_text
    cpu_text
    mem_text
    disk_text
    net_text
    topproc_text
    logins_text
    pkg_count_text
  fi
}

if [ -n "$OUT_FILE" ]; then
  run_report >"$OUT_FILE"
  info "Wrote report to $OUT_FILE"
else
  run_report
fi

exit 0
