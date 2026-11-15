#!/bin/bash
# Checks what local/bin/agent-guard blocks (2) and lets through (0).
guard="$(dirname "$0")/../local/bin/agent-guard"
fail=0
t() {
  printf '{"tool_input":{"command":%s}}' "$(jq -Rn --arg c "$2" '$c')" | bash "$guard" 2>/dev/null
  local r=$?
  [[ $r == "$1" ]] || { echo "FAIL (got $r, want $1): $2"; fail=1; }
}
t 2 'rm -rf ~'; t 2 'rm -rf ~/*'; t 2 'rm -rf $HOME/*';t 2 'rm -rf $HOME'; t 2 "rm -r -f \"$HOME\""; t 2 'rm -fr /'; t 2 'rm -rf *'
t 0 'rm -rf ~/tmp/build'; t 0 'rm -rf ./dist'; t 0 'rm -rf "$HOME/.cache/foo"'
t 2 'git push --force'; t 2 'git push -f origin feat'; t 2 'git push --force-with-lease origin main'
t 0 'git push --force-with-lease origin feat'; t 0 'git push -u origin feat'
t 2 'git reset --hard HEAD~1'; t 0 'git reset HEAD~1'; t 2 'git clean -fd'; t 0 'git clean -n'
t 2 'git checkout -- .'; t 2 'git restore .'; t 0 'git checkout main'; t 0 'git restore src/a.js'
t 2 'sudo dd if=x.iso of=/dev/sda'; t 0 'echo hello'
t 0 $'cat <<EOF\ngit worktree add\nno pushes, use -f\nEOF'
((fail)) || echo "agent-guard: all checks pass"
exit $fail
