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
Usage: log-grep.sh [-d DIR] [-a AFTER_DATE] [-b BEFORE_DATE] [-i] [-c] PATTERN

Search readable regular files under DIR with grep; skips unreadable paths.

  -d DIR          Root directory to search (default: /var/log)
  -a AFTER_DATE   Only files modified on or after this date (GNU date format)
  -b BEFORE_DATE  Only files modified on or before this date (GNU date format)
  -i              Case-insensitive match
  -c              Count-only mode (per-file match counts, like grep -c)

Example:
  log-grep.sh -d /var/log -a "2025-03-01" "error"
EOF
}

# --- arguments -------------------------------------------------------------
DIR="/var/log"
AFTER=""
BEFORE=""
ICASE=""
COUNT_MODE=""

while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -d)
    [ $# -ge 2 ] || die "-d requires a directory"
    DIR="$2"
    shift 2
    ;;
  -a)
    [ $# -ge 2 ] || die "-a requires a date"
    AFTER="$2"
    shift 2
    ;;
  -b)
    [ $# -ge 2 ] || die "-b requires a date"
    BEFORE="$2"
    shift 2
    ;;
  -i)
    ICASE=1
    shift
    ;;
  -c)
    COUNT_MODE=1
    shift
    ;;
  --)
    shift
    break
    ;;
  -*)
    die "unknown option: $1 (try --help)"
    ;;
  *)
    break
    ;;
  esac
done

PATTERN="${*:-}"
[ -n "$PATTERN" ] || die "PATTERN is required. Try --help."

[ -d "$DIR" ] || die "not a directory: $DIR"

# Validate / normalize BEFORE upper bound (start of day after BEFORE)
BEFORE_CUTOFF=""
if [ -n "$BEFORE" ]; then
  BEFORE_CUTOFF=$(date -d "$BEFORE + 1 day" +%Y-%m-%dT00:00:00 2>/dev/null) ||
    die "invalid BEFORE_DATE: $BEFORE"
fi

if [ -n "$AFTER" ]; then
  date -d "$AFTER" +%s >/dev/null 2>&1 || die "invalid AFTER_DATE: $AFTER"
fi

grep_args=()
[ -n "$ICASE" ] && grep_args+=(-i)
if [ -n "$COUNT_MODE" ]; then
  grep_args+=(-c)
else
  grep_args+=(-Hn)
fi

# --- search ----------------------------------------------------------------
# Build find predicates; suppress permission errors on unreadable directories.
mapfile -t files < <(
  {
    if [ -n "$AFTER" ] && [ -n "$BEFORE_CUTOFF" ]; then
      find "$DIR" -type f -readable -newermt "$AFTER" ! -newermt "$BEFORE_CUTOFF" -print 2>/dev/null
    elif [ -n "$AFTER" ]; then
      find "$DIR" -type f -readable -newermt "$AFTER" -print 2>/dev/null
    elif [ -n "$BEFORE_CUTOFF" ]; then
      find "$DIR" -type f -readable ! -newermt "$BEFORE_CUTOFF" -print 2>/dev/null
    else
      find "$DIR" -type f -readable -print 2>/dev/null
    fi
  } || true
)

if [ "${#files[@]}" -eq 0 ] || { [ "${#files[@]}" -eq 1 ] && [ -z "${files[0]:-}" ]; }; then
  info "No readable files found under $DIR (with current filters)."
  exit 0
fi

status=1
for f in "${files[@]}"; do
  [ -n "$f" ] || continue
  [ -r "$f" ] || continue
  if grep "${grep_args[@]}" -- "$PATTERN" "$f" 2>/dev/null; then
    status=0
  fi
done

exit "$status"
