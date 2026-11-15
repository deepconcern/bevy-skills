#!/usr/bin/env bash
# SessionStart hook: compare the project's locked Bevy version with the versions the installed
# bevy skill supports. Prints one line of context on a mismatch and nothing otherwise.
# No network, no jq (Git Bash on Windows has neither guaranteed). Always exits 0.

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
project="${CLAUDE_PROJECT_DIR:-$PWD}"
skill="$root/skills/bevy/SKILL.md"
lock="$project/Cargo.lock"

[ -f "$lock" ] && [ -f "$skill" ] || exit 0

# Cargo.lock lists `name = "bevy"` followed by `version = "x.y.z"`.
locked=$(awk '/^name = "bevy"$/ { getline; gsub(/version = |"/, ""); print; exit }' "$lock")
[ -n "$locked" ] || exit 0

minor=$(printf '%s' "$locked" | awk -F. '{ print $1 "." $2 }')
supported=$(awk -F'"' '/^  supported-versions:/ { print $2; exit }' "$skill")

for v in $supported; do
  [ "$v" = "$minor" ] && exit 0
done

echo "bevy-skills: Cargo.lock has bevy $locked, but the installed bevy skill supports ${supported:-unknown}. Don't rely on its version-specific references; use the locked crate source and examples (~/.cargo/registry/src/*/bevy-$locked/), and update the bevy-skills marketplace (or pin a matching tag)."
exit 0
