#!/usr/bin/env bash
# Compare every skill's metadata target-version with the newest stable release on crates.io.
# Prints one TSV line per skill: crate, targeted minor, newest version, status (current|stale).
# Exit code is 0 even when something is stale; the workflow decides what to do with the output.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
ua="bevy-skills-staleness-check (https://github.com/deepconcern/bevy-skills)"

# Release line used for comparison: "0.20" for 0.x crates, "1" for 1.x and later.
line() { awk -F. '{ if ($1 == "0") print $1 "." $2; else print $1 }' <<<"$1"; }

for skill in "$repo"/plugins/*/skills/*/SKILL.md; do
  crate=$(awk -F'"' '/^  target-crate:/ { print $2; exit }' "$skill")
  target=$(awk -F'"' '/^  target-version:/ { print $2; exit }' "$skill")
  if [ -z "$crate" ] || [ -z "$target" ]; then
    echo "warning: $skill has no metadata target-crate/target-version" >&2
    continue
  fi
  newest=$(curl -fsS -A "$ua" "https://crates.io/api/v1/crates/$crate" | jq -r '.crate.max_stable_version')
  status=current
  [ "$(line "$newest")" = "$(line "$target")" ] || status=stale
  printf '%s\t%s\t%s\t%s\n' "$crate" "$target" "$newest" "$status"
done
