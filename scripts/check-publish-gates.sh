#!/usr/bin/env bash
set -euo pipefail

result_dir="${1:-}"
confirmation_file="${2:-}"
if [[ -z "$result_dir" || -z "$confirmation_file" ]]; then
  echo "usage: $0 results/RUN_ID confirmations/CONFIRMATION.md" >&2
  exit 64
fi

run_id="$(basename "$result_dir")"
audit_file="audits/${run_id}.md"
required_steps=(
  openai-cache openai-build openai-navier-stokes-axioms openai-euler-axioms
  buckmaster-euler-blowup-build buckmaster-euler-blowup-axioms
  buckmaster-boussinesq-blowup-build buckmaster-boussinesq-blowup-axioms
  buckmaster-affinecore-build buckmaster-affinecore-axioms
)

test "$(tr -d '[:space:]' < "$result_dir/overall-exit-code.txt")" = "0"
(cd "$result_dir" && sha256sum --check SHA256SUMS >/dev/null)
for step in "${required_steps[@]}"; do
  test "$(jq -r .exit_code "$result_dir/$step.json")" = "0"
done

test -f "$audit_file"
if grep -q 'REPLACE_ME' "$audit_file"; then
  echo "axiom audit still contains placeholders" >&2
  exit 1
fi
git ls-files --error-unmatch "$audit_file" >/dev/null
git log -1 --format='%H' -- "$audit_file" | grep -q .

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

echo "PUBLICATION GATES PASS for $run_id"
echo "Publish in order: Lean Zulip -> Hacker News -> r/accelerate -> X"
