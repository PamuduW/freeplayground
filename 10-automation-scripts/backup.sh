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
Usage: backup.sh [-o OUTPUT_DIR] [-e EXCLUDE_PATTERN] [-k N] SOURCE_DIR

Create a timestamped gzip-compressed tar archive of SOURCE_DIR.

  -o OUTPUT_DIR       Directory for the archive (default: current directory)
  -e EXCLUDE_PATTERN  tar --exclude pattern (repeatable)
  -k N                 Keep only the N newest matching backups in OUTPUT_DIR (0 = skip pruning)

Archive name: backup_<dirname>_YYYYMMDD_HHMMSS.tar.gz

After creation, verifies the archive with tar -tzf and prints size and member count.
EOF
}

# --- arguments -------------------------------------------------------------
OUTPUT_DIR="."
EXCLUDES=()
KEEP=0
SOURCE=""

while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -o)
    [ $# -ge 2 ] || die "-o requires a directory"
    OUTPUT_DIR="$2"
    shift 2
    ;;
  -e)
    [ $# -ge 2 ] || die "-e requires a pattern"
    EXCLUDES+=("$2")
    shift 2
    ;;
  -k)
    [ $# -ge 2 ] || die "-k requires a number"
    [[ $2 =~ ^[0-9]+$ ]] || die "-k must be a non-negative integer"
    KEEP="$2"
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
    [ -z "$SOURCE" ] || die "unexpected extra argument: $1"
    SOURCE="$1"
    shift
    ;;
  esac
done

while [ $# -gt 0 ]; do
  [ -z "$SOURCE" ] || die "unexpected extra argument: $1"
  SOURCE="$1"
  shift
done

[ -n "$SOURCE" ] || die "SOURCE_DIR is required. Try --help."
[ -d "$SOURCE" ] || die "not a directory: $SOURCE"

ABS_SOURCE=$(cd "$SOURCE" && pwd)
BASE_NAME=$(basename "$ABS_SOURCE")
PARENT=$(dirname "$ABS_SOURCE")

mkdir -p "$OUTPUT_DIR" || die "cannot create output directory: $OUTPUT_DIR"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)

TS=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="backup_${BASE_NAME}_${TS}.tar.gz"
ARCHIVE_PATH="${OUTPUT_DIR}/${ARCHIVE_NAME}"

TAR_EXCLUDE=()
for pat in "${EXCLUDES[@]}"; do
  TAR_EXCLUDE+=(--exclude="$pat")
done

info "Creating archive: $ARCHIVE_PATH"
tar -czf "$ARCHIVE_PATH" "${TAR_EXCLUDE[@]}" -C "$PARENT" "$BASE_NAME" ||
  die "tar create failed"

info "Verifying archive integrity..."
tar -tzf "$ARCHIVE_PATH" >/dev/null || die "archive verification failed (tar -tzf)"

SIZE_BYTES=$(stat -c '%s' "$ARCHIVE_PATH")
FILE_COUNT=$(tar -tzf "$ARCHIVE_PATH" | wc -l)
info "Backup size: ${SIZE_BYTES} bytes"
info "Archive entries (lines from tar -t): ${FILE_COUNT}"

if [ "$KEEP" -gt 0 ]; then
  shopt -s nullglob
  mapfile -t existing < <(
    for f in "$OUTPUT_DIR"/"backup_${BASE_NAME}"_*.tar.gz; do
      [ -f "$f" ] || continue
      printf '%s\t%s\n' "$(stat -c '%Y' "$f")" "$f"
    done | sort -nr | cut -f2-
  )
  shopt -u nullglob
  if [ "${#existing[@]}" -gt "$KEEP" ]; then
    info "Pruning old backups (keeping ${KEEP} newest)..."
    idx=0
    for f in "${existing[@]}"; do
      idx=$((idx + 1))
      if [ "$idx" -gt "$KEEP" ]; then
        rm -f -- "$f" && info "removed old backup: $f"
      fi
    done
  fi
fi

info "Done: $ARCHIVE_PATH"

exit 0
