#!/usr/bin/env bash
# PreToolUse hook: blocks any tool call whose input references constants.js.
input=$(cat)

if printf '%s' "$input" | jq -e '.tool_input | tostring | test("constants\\.js")' >/dev/null 2>&1; then
  echo "No puedo leer ese archivo" >&2
  exit 2
fi
exit 0
