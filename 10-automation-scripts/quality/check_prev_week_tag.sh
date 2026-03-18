#!/usr/bin/env bash
set -euo pipefail

branch=$(git rev-parse --abbrev-ref HEAD)

week_num=$(echo "$branch" | sed -n 's|^week/0*\([0-9]*\)-.*|\1|p')
if [ -z "$week_num" ]; then
  exit 0
fi

if [ "$week_num" -le 1 ]; then
  exit 0
fi

prev=$(printf "week-%02d" $((week_num - 1)))

if git rev-parse "$prev" >/dev/null 2>&1; then
  exit 0
fi

echo "WARNING: tag '$prev' not found."
echo "Did you forget to run 'make tag-week WEEK=$(printf "%02d" $((week_num - 1)))' after merging?"
exit 1
