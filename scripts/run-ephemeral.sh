#!/usr/bin/env bash
set -Eeuo pipefail

if command -v terraform >/dev/null 2>&1; then
  tf_bin="terraform"
elif command -v tofu >/dev/null 2>&1; then
  tf_bin="tofu"
else
  echo "Terraform or OpenTofu is required." >&2
  exit 127
fi
TF=("$tf_bin" -chdir=infra)
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30)
created=0
destroyed=0

destroy_stack() {
  local original_status="${1:-$?}" attempt
  trap - EXIT INT TERM HUP

  if [[ "$created" -eq 0 || "$destroyed" -eq 1 ]]; then
    exit "$original_status"
  fi

  echo "Teardown armed: destroying all resources in this Terraform stack." >&2
  for attempt in 1 2 3; do
    if "${TF[@]}" destroy -auto-approve; then
      if [[ -z "$("${TF[@]}" state list)" ]]; then
        destroyed=1
        echo "Teardown confirmed: Terraform state contains no managed resources." >&2
        exit "$original_status"
      fi
    fi
    echo "Teardown attempt $attempt failed; retrying." >&2
    sleep 10
  done

  echo "CRITICAL: automatic teardown could not be confirmed." >&2
  echo "Immediately inspect the DigitalOcean control panel for tag 'ephemeral' and run: make destroy" >&2
  exit 70
}

trap 'destroy_stack $?' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP

scripts/test.sh
"${TF[@]}" init
"${TF[@]}" plan -out=verify.tfplan

# Set before apply: a partially successful apply must also be cleaned up.
created=1
"${TF[@]}" apply verify.tfplan

ip_address="$("${TF[@]}" output -raw ipv4_address)"
ssh "${SSH_OPTS[@]}" "verifier@$ip_address" \
  'cloud-init status --wait && test -x /opt/lean-verifier/verify.sh'

verify_status=0
ssh "${SSH_OPTS[@]}" "verifier@$ip_address" \
  'sudo /opt/lean-verifier/verify.sh all' || verify_status=$?

mkdir -p results
rsync -av --partial -e "ssh ${SSH_OPTS[*]}" \
  "verifier@$ip_address:/var/lib/lean-verification/results/" results/

latest_run="$(find results -mindepth 1 -maxdepth 1 -type d -name '20*T*Z' -print | sort | tail -n 1)"
if [[ -z "$latest_run" ]]; then
  echo "No downloaded result directory found." >&2
  exit 1
fi
(cd "$latest_run" && sha256sum --check SHA256SUMS)
echo "Evidence downloaded and checksums verified in $latest_run"

if [[ "$verify_status" -ne 0 ]]; then
  echo "One or more verification steps failed; evidence was preserved." >&2
  exit "$verify_status"
fi
