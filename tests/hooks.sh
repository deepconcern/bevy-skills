#!/usr/bin/env bash
# Exercises the bevy plugin's hook scripts with fake inputs. Run from anywhere.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
plugin="$repo/plugins/bevy"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0

check() { # name, expected (empty|nonempty), actual
  if { [ "$2" = empty ] && [ -z "$3" ]; } || { [ "$2" = nonempty ] && [ -n "$3" ]; }; then
    echo "ok   - $1"
  else
    echo "FAIL - $1 (expected $2, got: '$3')"; fail=1
  fi
}

supported=$(awk -F'"' '/^  supported-versions:/ { print $2; exit }' "$plugin/skills/bevy/SKILL.md")
current=${supported%% *}

mkdir -p "$tmp/match" "$tmp/mismatch" "$tmp/nolock" "$tmp/nobevy"
printf '[[package]]\nname = "bevy"\nversion = "%s.1"\n' "$current" > "$tmp/match/Cargo.lock"
printf '[[package]]\nname = "bevy"\nversion = "0.999.0"\n' > "$tmp/mismatch/Cargo.lock"
printf '[[package]]\nname = "serde"\nversion = "1.0.0"\n' > "$tmp/nobevy/Cargo.lock"

run_lock() { CLAUDE_PLUGIN_ROOT="$plugin" CLAUDE_PROJECT_DIR="$1" bash "$plugin/scripts/check-lock.sh"; }
check "lock hook silent on supported version" empty "$(run_lock "$tmp/match")"
check "lock hook warns on unsupported version" nonempty "$(run_lock "$tmp/mismatch")"
check "lock hook silent without Cargo.lock" empty "$(run_lock "$tmp/nolock")"
check "lock hook silent without bevy" empty "$(run_lock "$tmp/nobevy")"

run_web() { printf '%s' "$1" | CLAUDE_PLUGIN_ROOT="$plugin" bash "$plugin/scripts/warn-outdated-source.sh"; }
out=$(run_web '{"tool_name":"WebFetch","tool_input":{"url":"https://bevy-cheatbook.github.io/programming/systems.html"}}')
check "web hook flags the cheat book" nonempty "$out"
if [ -n "$out" ]; then
  if command -v jq >/dev/null; then
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | length > 0' >/dev/null; then
      echo "ok   - web hook output is valid JSON"
    else
      echo "FAIL - web hook output is not valid JSON"; fail=1
    fi
  fi
fi
check "web hook flags bevy main branch" nonempty "$(run_web '{"tool_input":{"url":"https://github.com/bevyengine/bevy/tree/main/examples"}}')"
check "web hook silent on pinned docs.rs" empty "$(run_web '{"tool_input":{"url":"https://docs.rs/bevy/0.20.1/bevy/"}}')"

exit $fail
