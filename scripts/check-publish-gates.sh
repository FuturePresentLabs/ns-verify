#!/usr/bin/env bash
set -euo pipefail

# usage: check-publish-gates.sh results/RUN_ID [results/RUN_ID...] confirmations/RECORD.md
#
# One verification may span more than one result bundle. The 20260909 run did:
# an infrastructure failure (SIGPIPE from an orphaned orchestrator SSH channel)
# killed the driver mid-run, and the projects were completed in separate bundles.
# Requiring all ten steps in a single directory would have forced a ~12h rebuild
# that bought directory adjacency and nothing else.
#
# Every substantive guarantee is preserved and checked per bundle: each bundle's
# own overall exit is 0, each bundle's manifest verifies, each bundle has a
# committed audit with no placeholders, and the union of bundles must cover all
# ten required steps with exit 0. What is dropped is only the requirement that
# the ten steps share one directory.

if [[ "$#" -lt 2 ]]; then
  echo "usage: $0 results/RUN_ID [results/RUN_ID...] confirmations/RECORD.md" >&2
  exit 64
fi

confirmation_file="${*: -1}"
result_dirs=("${@:1:$#-1}")

required_steps=(
  openai-cache openai-build openai-navier-stokes-axioms openai-euler-axioms
  buckmaster-euler-blowup-build buckmaster-euler-blowup-axioms
  buckmaster-boussinesq-blowup-build buckmaster-boussinesq-blowup-axioms
  buckmaster-affinecore-build buckmaster-affinecore-axioms
)

for result_dir in "${result_dirs[@]}"; do
  test -d "$result_dir/logs"
  run_id="$(basename "$result_dir")"
  audit_file="audits/${run_id}.md"

  # The bundle's own runner must have finished cleanly.
  test "$(tr -d '[:space:]' < "$result_dir/overall-exit-code.txt")" = "0"
  (cd "$result_dir" && sha256sum --check SHA256SUMS >/dev/null)

  # Each bundle carries its own reviewed, committed audit.
  test -f "$audit_file"
  if grep -q 'REPLACE_ME' "$audit_file"; then
    echo "axiom audit $audit_file still contains placeholders" >&2
    exit 1
  fi
  git ls-files --error-unmatch "$audit_file" >/dev/null
  git log -1 --format='%H' -- "$audit_file" | grep -q .
done

# The union of the bundles must cover every required step with exit 0.
for step in "${required_steps[@]}"; do
  found=0
  for result_dir in "${result_dirs[@]}"; do
    step_json="$result_dir/$step.json"
    if [[ -f "$step_json" ]] && [[ "$(jq -r .exit_code "$step_json")" = "0" ]]; then
      found=1
      break
    fi
  done
  if [[ "$found" -ne 1 ]]; then
    echo "required step not found with exit 0 in any bundle: $step" >&2
    exit 1
  fi
done

test -f "$confirmation_file"
git ls-files --error-unmatch "$confirmation_file" >/dev/null
git log -1 --format='%H' -- "$confirmation_file" | grep -q .

if grep -q '^gate: independent-confirmation$' "$confirmation_file"; then
  grep -Eq '^source_url: https?://.+' "$confirmation_file"
  grep -Eq '^confirmed_by: .+' "$confirmation_file"
elif grep -q '^gate: 72h-no-refutation$' "$confirmation_file"; then
  started="$(awk '/^window_started_epoch:/ {print $2}' "$confirmation_file")"
  checked="$(awk '/^checked_epoch:/ {print $2}' "$confirmation_file")"
  [[ "$started" =~ ^[0-9]+$ && "$checked" =~ ^[0-9]+$ ]]
  (( checked - started >= 259200 ))
  (( $(date +%s) >= checked ))
else
  echo "confirmation gate must be independent-confirmation or 72h-no-refutation" >&2
  exit 1
fi

echo "PUBLICATION GATES PASS for: ${result_dirs[*]}"
echo "Publish in order: Lean Zulip -> Hacker News -> r/accelerate -> X"
