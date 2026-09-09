#!/usr/bin/env bash
set -euo pipefail

result_dir="${1:-}"
if [[ -z "$result_dir" || ! -d "$result_dir/logs" ]]; then
  echo "usage: $0 results/RUN_ID" >&2
  exit 64
fi

run_id="$(basename "$result_dir")"
audit_file="audits/${run_id}.md"
mkdir -p audits
if [[ -e "$audit_file" ]]; then
  echo "refusing to overwrite $audit_file" >&2
  exit 1
fi

overall="$(tr -d '[:space:]' < "$result_dir/overall-exit-code.txt")"
manifest_hash="$(sha256sum "$result_dir/SHA256SUMS" | awk '{print $1}')"

{
  echo "# Axiom and warning audit: $run_id"
  echo
  echo "- Result bundle: \`$result_dir\`"
  echo "- Overall runner exit: \`$overall\`"
  echo "- SHA256SUMS digest: \`$manifest_hash\`"
  echo "- Reviewer: \`REPLACE_ME\`"
  echo "- Review UTC: \`REPLACE_ME\`"
  echo "- Conclusion: \`REPLACE_ME_PASS_OR_FAIL\`"
  echo
  echo "## Axiom output"
  echo
  echo '```text'
  grep -H -E "axioms|propext|Classical.choice|Quot.sound" "$result_dir"/logs/*axioms.log || true
  echo '```'
  echo
  echo "## Sorry and error scan"
  echo
  echo '```text'
  grep -H -E "declaration uses 'sorry'|(^|[^a-z])error:" "$result_dir"/logs/*.log || true
  echo '```'
  echo
  echo "## Reviewer notes"
  echo
  echo "REPLACE_ME: inspect every match against the pinned source and explain all intentional challenge-file warnings."
} > "$audit_file"

echo "Created $audit_file. Review every line, replace all REPLACE_ME fields, then commit it."

