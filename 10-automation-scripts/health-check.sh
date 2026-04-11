#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------
die() {
  echo "ERROR: $*" >&2
  exit 1
}
die_usage() {
  echo "ERROR: $*" >&2
  exit 2
}
info() { echo "$*"; }

USE_COLOR=1
OUTPUT_JSON=0
WARN_DISK=80
WARN_MEM=80
SERVICES_LIST="sshd,docker"
declare -a CHECKS_SELECTED=()

RED=""
YELLOW=""
GREEN=""
NC=""

setup_colors() {
  if [ "$USE_COLOR" -eq 1 ] && [ -t 1 ]; then
    RED=$'\033[31m'
    YELLOW=$'\033[33m'
    GREEN=$'\033[32m'
    NC=$'\033[0m'
  fi
}

severity_color() {
  case "$1" in
  OK) echo "$GREEN" ;;
  WARN) echo "$YELLOW" ;;
  CRIT) echo "$RED" ;;
  *) echo "" ;;
  esac
}

usage() {
  cat <<EOF
Usage: health-check.sh [OPTIONS] [CHECKS...]

Run modular system health checks.

Checks (default: all):
  disk      Filesystem capacity
  memory    RAM usage
  cpu       Load average vs CPU count
  services  systemd active state for configured services
  network   Default route and basic connectivity
  all       All of the above

Options:
  -h, --help              Show this help
      --no-color          Disable ANSI colors
      --json              Print simple JSON lines (key=value per line / one object per check)
      --warn-disk PCT     Disk use warning threshold (default: 80)
      --warn-mem PCT      Memory use warning threshold (default: 80)
      --services LIST     Comma-separated service names (default: sshd,docker)

Exit codes: 0 if no CRIT, 1 if any CRIT, 2 on usage/parse errors.
EOF
}

# --- parse args ------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  --no-color)
    USE_COLOR=0
    shift
    ;;
  --json)
    OUTPUT_JSON=1
    USE_COLOR=0
    shift
    ;;
  --warn-disk)
    [ $# -ge 2 ] || die "--warn-disk requires a value"
    [[ $2 =~ ^[0-9]+$ ]] || die "--warn-disk must be an integer"
    WARN_DISK="$2"
    shift 2
    ;;
  --warn-mem)
    [ $# -ge 2 ] || die "--warn-mem requires a value"
    [[ $2 =~ ^[0-9]+$ ]] || die "--warn-mem must be an integer"
    WARN_MEM="$2"
    shift 2
    ;;
  --services)
    [ $# -ge 2 ] || die "--services requires a value"
    SERVICES_LIST="$2"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  -*)
    die_usage "unknown option: $1 (try --help)"
    ;;
  *)
    CHECKS_SELECTED+=("$1")
    shift
    ;;
  esac
done

while [ $# -gt 0 ]; do
  CHECKS_SELECTED+=("$1")
  shift
done

setup_colors

if [ "${#CHECKS_SELECTED[@]}" -eq 0 ]; then
  CHECKS_SELECTED=(all)
fi

expand_checks() {
  local -n out="$1"
  local c
  out=()
  for c in "${CHECKS_SELECTED[@]}"; do
    case "$c" in
    all)
      out+=(disk memory cpu services network)
      ;;
    disk | memory | cpu | services | network)
      out+=("$c")
      ;;
    *)
      die_usage "unknown check: $c (try --help)"
      ;;
    esac
  done
}

declare -a RUN_CHECKS=()
expand_checks RUN_CHECKS

# Dedupe while preserving order
declare -A SEEN=()
declare -a UNIQUE_CHECKS=()
for c in "${RUN_CHECKS[@]}"; do
  [ -n "${SEEN[$c]:-}" ] && continue
  SEEN[$c]=1
  UNIQUE_CHECKS+=("$c")
done
RUN_CHECKS=("${UNIQUE_CHECKS[@]}")

PASSED=0
WARNINGS=0
CRITICAL=0

emit_text() {
  local name="$1" sev="$2" detail="$3"
  local col
  col=$(severity_color "$sev")
  info "${col}[${sev}]${NC} ${name}: ${detail}"
}

emit_json() {
  local name="$1" sev="$2" detail="$3"
  detail=${detail//\\/\\\\}
  detail=${detail//\"/\\\"}
  printf '{"check":"%s","status":"%s","detail":"%s"}\n' "$name" "$sev" "$detail"
}

record() {
  local name="$1" sev="$2" detail="$3"
  case "$sev" in
  OK) PASSED=$((PASSED + 1)) ;;
  WARN) WARNINGS=$((WARNINGS + 1)) ;;
  CRIT) CRITICAL=$((CRITICAL + 1)) ;;
  esac
  if [ "$OUTPUT_JSON" -eq 1 ]; then
    emit_json "$name" "$sev" "$detail"
  else
    emit_text "$name" "$sev" "$detail"
  fi
}

# --- check implementations -----------------------------------------------
check_disk() {
  local worst=OK line use mp msg
  local out
  out=$(df -P -x tmpfs -x devtmpfs 2>/dev/null | tail -n +2) || true
  if [ -z "$out" ]; then
    record disk CRIT "df produced no output"
    return
  fi
  while read -r line; do
    use=$(echo "$line" | awk '{gsub(/%/,"",$5); print $5}')
    mp=$(echo "$line" | awk '{print $6}')
    [ -n "$use" ] || continue
    if [ "$use" -ge 95 ]; then
      worst=CRIT
      msg="${mp} ${use}% full"
      break
    elif [ "$use" -ge "$WARN_DISK" ]; then
      [ "$worst" = OK ] && worst=WARN
      msg="${mp} ${use}% full"
    fi
  done <<<"$out"
  case "$worst" in
  OK) record disk OK "all monitored filesystems under ${WARN_DISK}% use" ;;
  WARN) record disk WARN "$msg" ;;
  CRIT) record disk CRIT "$msg" ;;
  esac
}

check_memory() {
  local pct
  if [ -r /proc/meminfo ]; then
    local total avail
    total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    if [ -z "${total:-}" ] || [ "$total" -eq 0 ] || [ -z "${avail:-}" ]; then
      record memory CRIT "could not parse /proc/meminfo"
      return
    fi
    pct=$((100 - (avail * 100 / total)))
  else
    record memory CRIT "/proc/meminfo not readable"
    return
  fi

  if [ "$pct" -ge 95 ]; then
    record memory CRIT "memory use ~${pct}% (MemAvailable vs MemTotal)"
  elif [ "$pct" -ge "$WARN_MEM" ]; then
    record memory WARN "memory use ~${pct}% (MemAvailable vs MemTotal)"
  else
    record memory OK "memory use ~${pct}% (under ${WARN_MEM}% warn threshold)"
  fi
}

check_cpu() {
  local n load1
  n=$(nproc 2>/dev/null || echo 1)
  load1=$(awk '{print $1}' /proc/loadavg 2>/dev/null) || load1=""
  if [ -z "$load1" ]; then
    record cpu CRIT "could not read /proc/loadavg"
    return
  fi
  if awk -v l="$load1" -v c="$n" 'BEGIN{exit !(l > c * 1.5)}'; then
    record cpu CRIT "load ${load1} vs ${n} CPUs (high)"
  elif awk -v l="$load1" -v c="$n" 'BEGIN{exit !(l > c)}'; then
    record cpu WARN "load ${load1} vs ${n} CPUs (elevated)"
  else
    record cpu OK "load ${load1} vs ${n} CPUs"
  fi
}

check_services() {
  local svc status overall=OK detail=""
  if ! command -v systemctl >/dev/null 2>&1; then
    record services WARN "systemctl not available; skipping service checks"
    return
  fi
  IFS=',' read -ra svc_arr <<<"$SERVICES_LIST"
  for svc in "${svc_arr[@]}"; do
    svc=$(echo "$svc" | xargs)
    [ -n "$svc" ] || continue
    status=$(systemctl is-active "$svc" 2>/dev/null || true)
    if [ "$status" = active ]; then
      detail+="${svc}=active; "
    else
      overall=CRIT
      detail+="${svc}=${status:-inactive}; "
    fi
  done
  [ -n "$detail" ] || detail="(no services configured)"
  record services "$overall" "$detail"
}

check_network() {
  if ip route show default 2>/dev/null | grep -q .; then
    if command -v ping >/dev/null 2>&1; then
      if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        record network OK "default route present; ping 8.8.8.8 ok"
      else
        record network WARN "default route present; ping 8.8.8.8 failed"
      fi
    else
      record network WARN "default route present; ping not installed"
    fi
  else
    record network CRIT "no default route"
  fi
}

# --- run -------------------------------------------------------------------
for chk in "${RUN_CHECKS[@]}"; do
  case "$chk" in
  disk) check_disk ;;
  memory) check_memory ;;
  cpu) check_cpu ;;
  services) check_services ;;
  network) check_network ;;
  *) die "internal error: unhandled check $chk" ;;
  esac
done

SUMMARY="${PASSED} checks passed, ${WARNINGS} warnings, ${CRITICAL} critical"
if [ "$OUTPUT_JSON" -eq 1 ]; then
  printf '{"summary":"%s","passed":%s,"warnings":%s,"critical":%s}\n' \
    "$SUMMARY" "$PASSED" "$WARNINGS" "$CRITICAL"
else
  if [ "$CRITICAL" -gt 0 ]; then
    summary_state="CRIT"
  elif [ "$WARNINGS" -gt 0 ]; then
    summary_state="WARN"
  else
    summary_state="OK"
  fi
  col=$(severity_color "$summary_state")
  info "${col}${SUMMARY}${NC}"
fi

if [ "$CRITICAL" -gt 0 ]; then
  exit 1
fi
exit 0
