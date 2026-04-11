#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------
die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() { echo "$*"; }
warn() { echo "WARN: $*" >&2; }

usage() {
  cat <<'EOF'
Usage: cleanup.sh [-n] [-v] [-d DAYS] [DIR...]

Remove regular files older than DAYS under each directory.

  -n       Dry run only (no deletion)
  -v       Verbose: list each path
  -d DAYS  Age threshold in days (default: 30). Uses find -mtime +DAYS.

Default directories if none given: /tmp, ~/.cache, /var/tmp

Without -n: runs a dry-run pass (summary only), then deletes. With -n: dry run only.
Permission errors are skipped with a warning where possible.
EOF
}

# --- arguments -------------------------------------------------------------
DRY_ONLY=0
VERBOSE=0
DAYS=30
POSITIONAL=()

while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -n)
    DRY_ONLY=1
    shift
    ;;
  -v)
    VERBOSE=1
    shift
    ;;
  -d)
    [ $# -ge 2 ] || die "-d requires a number"
    DAYS="$2"
    [[ $DAYS =~ ^[0-9]+$ ]] || die "DAYS must be a non-negative integer"
    [ "$DAYS" -ge 0 ] || die "DAYS must be >= 0"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  -*)
    die "unknown option: $1 (try --help)"
    ;;
  *)
    POSITIONAL+=("$1")
    shift
    ;;
  esac
done

while [ $# -gt 0 ]; do
  POSITIONAL+=("$1")
  shift
done

if [ "${#POSITIONAL[@]}" -eq 0 ]; then
  TARGETS=(/tmp "${HOME}/.cache" /var/tmp)
else
  TARGETS=("${POSITIONAL[@]}")
fi

# --- core ------------------------------------------------------------------
CANDIDATES=()

collect_all() {
  CANDIDATES=()
  local d line
  for d in "${TARGETS[@]}"; do
    if [ ! -d "$d" ]; then
      warn "skip (not a directory): $d"
      continue
    fi
    while IFS= read -r line; do
      [ -n "$line" ] && CANDIDATES+=("$line")
    done < <(find "$d" -xdev -type f -mtime "+${DAYS}" -print 2>/dev/null || true)
  done
}

compute_stats() {
  local total=0 count=0 p sz
  for p in "${CANDIDATES[@]}"; do
    [ -f "$p" ] || continue
    sz=$(stat -c '%s' "$p" 2>/dev/null) || {
      warn "could not stat: $p"
      continue
    }
    count=$((count + 1))
    total=$((total + sz))
  done
  echo "$count" "$total"
}

print_verbose_list() {
  local p sz
  for p in "${CANDIDATES[@]}"; do
    [ -f "$p" ] || continue
    sz=$(stat -c '%s' "$p" 2>/dev/null) || continue
    info "[preview] $p (${sz} bytes)"
  done
}

collect_all

read -r files_found total_bytes < <(compute_stats)

info "=== Dry run (preview) ==="
[ "$VERBOSE" -eq 1 ] && print_verbose_list
info "Summary (dry run): files_found=${files_found} total_size_bytes=${total_bytes}"

if [ "$DRY_ONLY" -eq 1 ]; then
  info "Dry run only (-n); no deletions performed."
  exit 0
fi

if [ "$files_found" -eq 0 ]; then
  info "Nothing to delete."
  exit 0
fi

info "=== Applying deletion ==="
deleted=0
skipped=0
for p in "${CANDIDATES[@]}"; do
  [ -f "$p" ] || {
    skipped=$((skipped + 1))
    continue
  }
  if rm -f -- "$p" 2>/dev/null; then
    deleted=$((deleted + 1))
    [ "$VERBOSE" -eq 1 ] && info "[delete] $p"
  else
    warn "could not delete: $p"
    skipped=$((skipped + 1))
  fi
done
info "Deletion pass: deleted=${deleted} skipped_or_missing=${skipped}"

collect_all
read -r remaining remain_bytes < <(compute_stats)
info "=== Post-delete summary ==="
info "Summary (post-check): files_found=${remaining} total_size_bytes=${remain_bytes}"

exit 0
