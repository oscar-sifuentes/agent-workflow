#!/usr/bin/env bash
# Worktree lifecycle for /deliver, so the orchestrator never hand-writes
# `rm`/`ln` with shell variables (agent safety checks block those and stall an
# unattended run).
#
#   worktree.sh integration <slug> [base]   create feat/<slug> in <parent>/<slug>,
#                                           from base (default: current branch),
#                                           and run commands.install from
#                                           .agents/project.json once
#   worktree.sh add <NN>                    (run inside the integration worktree)
#                                           create feat/<slug>--NN in <integration>--NN
#                                           and link node_modules; reuses it if present
#   worktree.sh remove <NN>                 unlink node_modules, remove the worktree,
#                                           delete the branch if it is merged
#   worktree.sh path <NN>                   print a ticket worktree's path
#   worktree.sh close <slug> [--discard]    remove the integration worktree <parent>/<slug>
#                                           and any ticket worktree left; keeps feat/<slug>
#                                           (it lives on in the PR) unless --discard,
#                                           which also deletes feat/<slug> and its ticket
#                                           branches. Run it from another worktree.
set -euo pipefail

cmd="${1:?usage: worktree.sh integration|add|remove|path ...}"
here="$(git rev-parse --show-toplevel)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
heavy="$script_dir/../../verify/scripts/heavy.sh"

# Read a dotted key from .agents/project.json (empty when missing).
project_cfg() {
  local file="$here/.agents/project.json"
  [ -f "$file" ] || return 0
  if command -v node >/dev/null 2>&1; then
    node -e 'const c=require(process.argv[1]);const v=process.argv[2].split(".").reduce((o,k)=>o&&o[k],c);if(v!=null)console.log(v)' "$file" "$1"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys;v=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    v=v.get(k) if isinstance(v,dict) else None
print(v if v is not None else "")' "$file" "$1"
  fi
}

integration_slug() {
  local branch
  branch="$(git -C "$here" branch --show-current)"
  case "$branch" in
    feat/*) echo "${branch#feat/}" ;;
    *) echo "worktree.sh: run '$cmd' inside the integration worktree (branch feat/<slug>), not '$branch'" >&2; exit 2 ;;
  esac
}

case "$cmd" in
  integration)
    slug="${2:?slug required}"
    base="${3:-$(git -C "$here" branch --show-current)}"
    dest="$(dirname "$here")/$slug"
    fresh=0
    if git -C "$here" show-ref --quiet "refs/heads/feat/$slug"; then
      if [ ! -d "$dest" ]; then git -C "$here" worktree add "$dest" "feat/$slug"; fresh=1; fi
    else
      git -C "$here" worktree add -b "feat/$slug" "$dest" "$base"; fresh=1
    fi
    install_cmd="$(project_cfg commands.install)"
    if [ -n "$install_cmd" ] && [ "$fresh" = 1 ]; then
      (cd "$dest" && bash "$heavy" sh -c "$install_cmd")
    fi
    echo "$dest"
    ;;
  add)
    nn="${2:?ticket number required}"
    slug="$(integration_slug)"
    dest="$here--$nn"
    branch="feat/$slug--$nn"
    if [ ! -d "$dest" ]; then
      if git -C "$here" show-ref --quiet "refs/heads/$branch"; then
        git -C "$here" worktree add "$dest" "$branch"
      else
        git -C "$here" worktree add -b "$branch" "$dest" "feat/$slug"
      fi
    fi
    if [ -d "$here/node_modules" ] && [ ! -e "$dest/node_modules" ]; then
      ln -s "$here/node_modules" "$dest/node_modules"
    fi
    echo "$dest"
    ;;
  remove)
    nn="${2:?ticket number required}"
    slug="$(integration_slug)"
    dest="$here--$nn"
    branch="feat/$slug--$nn"
    if [ -L "$dest/node_modules" ]; then unlink "$dest/node_modules"; fi
    if [ -d "$dest" ]; then git -C "$here" worktree remove "$dest"; fi
    if git -C "$here" branch --merged HEAD | grep -qx "  $branch"; then
      git -C "$here" branch -d "$branch" >/dev/null
    fi
    echo "removed $dest"
    ;;
  path)
    echo "$here--${2:?ticket number required}"
    ;;
  close)
    slug="${2:?slug required}"
    discard="${3:-}"
    dest="$(dirname "$here")/$slug"
    if [ "$here" = "$dest" ]; then
      echo "worktree.sh: run 'close' from another worktree, not from $dest itself" >&2; exit 2
    fi
    for wt in "$dest"--*; do
      [ -d "$wt" ] || continue
      if [ -L "$wt/node_modules" ]; then unlink "$wt/node_modules"; fi
      git -C "$here" worktree remove --force "$wt"
    done
    if [ -d "$dest" ]; then git -C "$here" worktree remove "$dest"; fi
    git -C "$here" worktree prune
    if [ "$discard" = "--discard" ]; then
      git -C "$here" for-each-ref --format='%(refname:short)' "refs/heads/feat/$slug" "refs/heads/feat/$slug--*" |
        while read -r b; do git -C "$here" branch -D "$b" >/dev/null; echo "deleted branch $b"; done
    fi
    echo "closed $dest"
    ;;
  *)
    echo "worktree.sh: unknown command '$cmd'" >&2; exit 2 ;;
esac
