#!/usr/bin/env bash
# PostToolUse hook for WebFetch/WebSearch: if the tool call or its result mentions a URL from the
# newest references/<minor>/outdated-sources.md table, add one line of context. Never blocks.
# No jq: the hook input is scanned as plain text. Always exits 0.

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
refs="$root/skills/bevy/references"
[ -d "$refs" ] || exit 0

newest=$(find "$refs" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -t. -k1,1n -k2,2n | tail -n 1)
table="$refs/$newest/outdated-sources.md"
[ -f "$table" ] || exit 0

input=$(cat)
[ -n "$input" ] || exit 0

hits=""
while IFS= read -r line; do
  # Rows look like: | `regex` | why |   (a literal | inside the regex is written \| )
  # shellcheck disable=SC2016 # the backticks are literal markdown, not command substitution
  pattern=$(printf '%s' "$line" | sed -n 's/^| `\(.*\)` | .*$/\1/p' | sed 's/\\|/|/g')
  [ -n "$pattern" ] || continue
  if printf '%s' "$input" | grep -Eq -- "$pattern"; then
    shown=$(printf '%s' "$pattern" | sed 's/\\\././g')
    hits="${hits:+$hits, }$shown"
  fi
done < <(grep '^| `' "$table")

[ -n "$hits" ] || exit 0

msg="bevy-skills: this result includes sources that don't match Bevy $newest ($hits). Use them for ideas only; check every API against the locked crate source before writing code. See the bevy skill's references/$newest/outdated-sources.md."
# JSON-escape backslashes and quotes.
msg=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$msg"
exit 0
