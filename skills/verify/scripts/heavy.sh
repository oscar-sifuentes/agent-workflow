#!/usr/bin/env bash
# Runs a heavy command (tests, tsc, build, docker) only when no other heavy
# command started through this script is running on the machine, so parallel
# agents don't freeze the laptop.
# Usage: bash .agents/skills/verify/scripts/heavy.sh <command> [args...]
set -uo pipefail
LOCK="${TMPDIR:-/tmp}/agent-heavy-command.lock"
waited=0
while ! mkdir "$LOCK" 2>/dev/null; do
  owner="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [ -n "$owner" ] && ! kill -0 "$owner" 2>/dev/null; then
    rm -rf "$LOCK"   # the previous owner died without cleaning up
    continue
  fi
  [ "$waited" -eq 0 ] && echo "heavy.sh: waiting for another heavy command (pid ${owner:-?})" >&2
  waited=1
  sleep 3
done
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT INT TERM
"$@"
