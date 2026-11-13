#!/usr/bin/env bash
# Dev servers for the e2e of /deliver, started from the integration worktrees so the
# browser tests the branch's code, not whatever the developer has running.
#
#   servers.sh free-port <from>                       print the first free port >= <from>
#   servers.sh start <name> <port> <dir> -- <cmd...>  start <cmd> in <dir> in the background,
#                                                     wait until <port> answers (up to 300 s)
#   servers.sh status                                 list the servers started here
#   servers.sh stop [<name>]                          stop one server, or all of them
#
# Pass env overrides inside the command: `-- env PORT=5101 npm run start`.
# State and logs live in .review/servers/ of the current worktree (git-ignored).
# Never use it for Docker builds or migrations.
set -euo pipefail

cmd="${1:?usage: servers.sh free-port|start|status|stop ...}"
state="$(git rev-parse --show-toplevel)/.review/servers"
mkdir -p "$state"

listening() { nc -z 127.0.0.1 "$1" >/dev/null 2>&1; }

kill_tree() {
  local pid="$1" child
  for child in $(pgrep -P "$pid" 2>/dev/null || true); do kill_tree "$child"; done
  kill "$pid" 2>/dev/null || true
}

stop_one() {
  local name="$1" pid
  [ -f "$state/$name.pid" ] || { echo "not running: $name"; return 0; }
  pid="$(cat "$state/$name.pid")"
  kill_tree "$pid"
  rm -f "$state/$name.pid"
  echo "stopped $name"
}

case "$cmd" in
  free-port)
    port="${2:?start port required}"
    while listening "$port"; do port=$((port + 1)); done
    echo "$port"
    ;;
  start)
    name="${2:?name required}"; port="${3:?port required}"; dir="${4:?dir required}"
    shift 4
    [ "${1:-}" = "--" ] && shift
    [ $# -gt 0 ] || { echo "servers.sh: no command after --" >&2; exit 2; }
    if listening "$port"; then
      echo "servers.sh: port $port is already in use; pick another with free-port" >&2
      exit 4
    fi
    [ -f "$state/$name.pid" ] && stop_one "$name" >/dev/null
    (cd "$dir" && nohup "$@" > "$state/$name.log" 2>&1 & echo $! > "$state/$name.pid")
    for _ in $(seq 1 300); do
      if listening "$port"; then echo "up $name http://localhost:$port (log: $state/$name.log)"; exit 0; fi
      if ! kill -0 "$(cat "$state/$name.pid")" 2>/dev/null; then
        echo "servers.sh: $name exited before listening on $port. Last lines of its log:" >&2
        tail -n 30 "$state/$name.log" >&2
        rm -f "$state/$name.pid"
        exit 1
      fi
      sleep 1
    done
    echo "servers.sh: $name did not listen on $port within 300 s. Last lines of its log:" >&2
    tail -n 30 "$state/$name.log" >&2
    stop_one "$name" >/dev/null
    exit 1
    ;;
  status)
    for f in "$state"/*.pid; do
      [ -f "$f" ] || { echo "no servers"; break; }
      name="$(basename "$f" .pid)"
      kill -0 "$(cat "$f")" 2>/dev/null && echo "running $name (pid $(cat "$f"))" || echo "dead $name"
    done
    ;;
  stop)
    if [ -n "${2:-}" ]; then
      stop_one "$2"
    else
      for f in "$state"/*.pid; do [ -f "$f" ] && stop_one "$(basename "$f" .pid)"; done
      true
    fi
    ;;
  *)
    echo "servers.sh: unknown command '$cmd'" >&2; exit 2 ;;
esac
