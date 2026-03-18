#!/usr/bin/env bash

set -euo pipefail

if ! command -v tree >/dev/null 2>&1; then
  echo "Error: 'tree' is not installed. Install it first and re-run this script." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="$ROOT_DIR/docs/info/tree.md"
IGNORE_PATTERN='.git|.cache|.ruff_cache|.venv|temp|.cursor|CLAUDE.md'

{
  echo "$(basename "$ROOT_DIR") (root)"
  tree -a --noreport -I "$IGNORE_PATTERN" "$ROOT_DIR" | tail -n +2
} >"$OUTPUT_FILE"

echo "Updated $OUTPUT_FILE"
