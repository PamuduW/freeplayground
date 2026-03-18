#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---------------------------------------------------------------
die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() { echo "$*"; }

# --- argument --------------------------------------------------------------
week_arg="${1:-}"
[ -z "$week_arg" ] && die "Usage: tag-week.sh NN  (e.g. tag-week.sh 03)"

week_num=$((10#$week_arg))
tag_name=$(printf "week-%02d" "$week_num")

# --- current state ---------------------------------------------------------
branch=$(git rev-parse --abbrev-ref HEAD)

latest_tag=$(git tag -l 'week-*' | sort -V | tail -1)
if [ -n "$latest_tag" ]; then
  latest_num=$((10#${latest_tag//week-/}))
else
  latest_num=0
fi

expected=$((latest_num + 1))

# --- shared validations ----------------------------------------------------
git rev-parse "$tag_name" >/dev/null 2>&1 &&
  die "tag '$tag_name' already exists."

if [ "$week_num" -ne "$expected" ]; then
  if [ "$latest_num" -eq 0 ]; then
    die "no week tags exist yet. Expected week-01, got $tag_name."
  else
    die "latest tag is '$latest_tag'. Next tag must be '$(printf "week-%02d" "$expected")', got '$tag_name'."
  fi
fi

# --- on main ---------------------------------------------------------------
if [ "$branch" = "main" ]; then
  git tag "$tag_name"
  info "Tagged HEAD of main as $tag_name."

# --- on a week branch (forgot to tag before branching) --------------------
else
  branch_week=$(echo "$branch" | sed -n 's|^week/0*\([0-9]*\)-.*|\1|p')
  [ -z "$branch_week" ] &&
    die "not on main or a week/NN-... branch. Checkout main first."

  [ "$week_num" -ge "$branch_week" ] &&
    die "on $branch — can only tag previous weeks from here (week-$(printf "%02d" "$week_num") >= current week $branch_week)."

  info "Fetching latest main from origin..."
  git fetch origin main

  git tag "$tag_name" origin/main ||
    die "failed to tag origin/main as $tag_name."
  info "Tagged origin/main as $tag_name (from $branch)."
fi

# --- push to all remotes ---------------------------------------------------
for remote in $(git remote); do
  info "Pushing $tag_name to $remote..."
  git push "$remote" "$tag_name"
done

info "Done: $tag_name tagged and pushed."
