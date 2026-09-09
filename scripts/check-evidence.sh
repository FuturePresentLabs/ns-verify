#!/usr/bin/env bash
set -euo pipefail

# Validates the evidence committed to this repository. This is what CI can
# honestly do: GitHub-hosted runners have 4 vCPU / 16 GiB RAM / 14 GiB disk and
# a 6-hour cap, while these builds peaked at ~33 GiB resident and ~70 GiB of
# disk over several hours. CI therefore re-checks the evidence, not the kernel.
#
# A bundle is treated as authoritative when its own runner exited 0. Bundles
# preserved as an incident record are skipped by construction, not by a list
# that can drift.

cd "$(dirname "$0")/.."

required_steps=(
  openai-cache openai-build openai-navier-stokes-axioms openai-euler-axioms
  buckmaster-euler-blowup-build buckmaster-euler-blowup-axioms
  buckmaster-boussinesq-blowup-build buckmaster-boussinesq-blowup-axioms
  buckmaster-affinecore-build buckmaster-affinecore-axioms
)
expected_axioms='[propext, Classical.choice, Quot.sound]'

authoritative=()
skipped=()
for dir in results/*/; do
  # `latest` is a convenience symlink to another bundle, not a distinct one.
  [[ -L "${dir%/}" ]] && continue
  [[ -f "$dir/overall-exit-code.txt" ]] || { skipped+=("$(basename "$dir") (no overall exit)"); continue; }
  if [[ "$(tr -d '[:space:]' < "$dir/overall-exit-code.txt")" == "0" ]]; then
    authoritative+=("${dir%/}")
  else
    skipped+=("$(basename "$dir") (overall exit $(tr -d '[:space:]' < "$dir/overall-exit-code.txt"))")
  fi
done

if [[ "${#authoritative[@]}" -eq 0 ]]; then
  echo "no authoritative bundles found" >&2
  exit 1
fi

echo "Authoritative bundles: ${authoritative[*]}"
for s in "${skipped[@]:-}"; do [[ -n "$s" ]] && echo "  skipped: $s"; done
echo

failures=0
uncovered=0
note() { echo "  FAIL: $*"; failures=$((failures + 1)); }

for dir in "${authoritative[@]}"; do
  run_id="$(basename "$dir")"
  echo "== $run_id"

  # 1. Manifest generated on the verifying machine still verifies.
  if (cd "$dir" && sha256sum --check SHA256SUMS >/dev/null 2>&1); then
    echo "  manifest verifies ($(grep -c . "$dir/SHA256SUMS") files)"
  else
    note "SHA256SUMS does not verify"
  fi

  # 2. Every recorded step in this bundle exited 0.
  for json in "$dir"/*-build.json "$dir"/*-axioms.json "$dir"/*-cache.json; do
    [[ -f "$json" ]] || continue
    code="$(jq -r .exit_code "$json")"
    [[ "$code" == "0" ]] || note "$(basename "$json" .json) exit $code"
  done

  # 3. Every audited theorem reports exactly the standard trio, and nothing
  #    anywhere depends on sorry.
  axiom_lines=0
  while IFS= read -r line; do
    axiom_lines=$((axiom_lines + 1))
    got="${line#*depends on axioms: }"
    [[ "$got" == "$expected_axioms" ]] || note "unexpected axioms: $line"
  done < <(cat "$dir"/logs/*axioms.log 2>/dev/null | tr -d '\r' | sed 's/\x1b\[[0-9;]*m//g' | grep "depends on axioms" || true)
  [[ "$axiom_lines" -gt 0 ]] || note "no axiom output found"
  echo "  audited theorems: $axiom_lines, all exactly the standard trio"

  if grep -q "sorryAx" "$dir"/logs/*axioms.log 2>/dev/null; then
    note "sorryAx present in axiom output"
  fi

  # 4. A reviewed audit exists with no placeholders left.
  if [[ -f "audits/$run_id.md" ]]; then
    grep -q 'REPLACE_ME' "audits/$run_id.md" && note "audit still has placeholders"
  else
    note "missing audits/$run_id.md"
  fi
done

# 5. The bundles together must cover every required step with exit 0.
echo
echo "== step coverage"
for step in "${required_steps[@]}"; do
  found=0
  for dir in "${authoritative[@]}"; do
    json="$dir/$step.json"
    [[ -f "$json" ]] && [[ "$(jq -r .exit_code "$json")" == "0" ]] && { found=1; break; }
  done
  [[ "$found" == "1" ]] || { note "required step uncovered: $step"; uncovered=$((uncovered + 1)); }
done
[[ "$uncovered" -eq 0 ]] && echo "  all ${#required_steps[@]} required steps covered with exit 0"

echo
if [[ "$failures" -ne 0 ]]; then
  echo "EVIDENCE CHECK FAILED: $failures problem(s)"
  exit 1
fi
echo "EVIDENCE CHECK PASSED"
