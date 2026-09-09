#!/usr/bin/env bash
set -uo pipefail

OPENAI_URL="https://github.com/openai/NavierStokesAndEuler.git"
OPENAI_COMMIT="8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538"
BUCKMASTER_URL="https://github.com/tristanbuckmaster/fluid_lean.git"
BUCKMASTER_COMMIT="d0124689230b58b4f86e7b90ac59de06404b3b6b"
ELAN_HOME="/home/verifier/.elan"
PATH="$ELAN_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export ELAN_HOME PATH

# shellcheck disable=SC1091
[[ -r /etc/lean-verifier.env ]] && source /etc/lean-verifier.env

TARGET="${1:-all}"
if [[ "$(id -u)" -eq 0 ]]; then
  exec sudo -u verifier --preserve-env=BUILD_JOBS /opt/lean-verifier/verify.sh "$TARGET"
fi

STATE_DIR="/var/lib/lean-verification"
WORK_DIR="$STATE_DIR/work"
RESULT_ROOT="$STATE_DIR/results"
BUILD_JOBS="${BUILD_JOBS:-24}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RESULT_DIR="$RESULT_ROOT/$RUN_ID"
mkdir -p "$WORK_DIR" "$RESULT_DIR/logs"
chown -R verifier:verifier "$STATE_DIR"

exec > >(tee -a "$RESULT_DIR/driver.log") 2>&1
echo "run_id=$RUN_ID target=$TARGET jobs=$BUILD_JOBS"

case "$TARGET" in
  all|openai|buckmaster-all|buckmaster-euler|buckmaster-boussinesq|buckmaster-affinecore) ;;
  *) echo "unknown target: $TARGET"; exit 64 ;;
esac

capture_environment() {
  {
    echo "utc_started=$(date -u --iso-8601=seconds)"
    echo "hostname=$(hostname)"
    echo "kernel=$(uname -srvmo)"
    echo "cpu_count=$(nproc)"
    echo "memory_kib=$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
    echo "disk_bytes=$(df --output=size -B1 /var/lib/lean-verification | tail -n 1 | tr -d ' ')"
    echo "elan=$(elan --version)"
    echo "git=$(git --version)"
  } > "$RESULT_DIR/environment.txt"
  lscpu > "$RESULT_DIR/lscpu.txt"
  lsblk --json --output NAME,SIZE,TYPE,MOUNTPOINTS > "$RESULT_DIR/lsblk.json"
  cp /var/lib/cloud/instance/cloud-config.txt "$RESULT_DIR/cloud-config.txt" 2>/dev/null || true
}

checkout_exact() {
  local name="$1" url="$2" commit="$3" dir
  dir="$WORK_DIR/$name"
  if [[ ! -d "$dir/.git" ]]; then
    git clone --no-checkout "$url" "$dir"
  fi
  git -C "$dir" fetch --force origin "$commit"
  git -C "$dir" checkout --detach --force "$commit"
  git -C "$dir" clean -ffdx
  test "$(git -C "$dir" rev-parse HEAD)" = "$commit"
  git -C "$dir" status --porcelain=v1 > "$RESULT_DIR/${name}-git-status.txt"
  git -C "$dir" show --no-patch --format=fuller HEAD > "$RESULT_DIR/${name}-commit.txt"
  git -C "$dir" bundle create "$RESULT_DIR/${name}-${commit}.bundle" HEAD
}

run_step() {
  local label="$1" directory="$2"
  shift 2
  local log="$RESULT_DIR/logs/${label}.log" start end status
  start="$(date -u --iso-8601=seconds)"
  echo "START $label at $start"
  (
    cd "$directory" || exit
    /usr/bin/time -v "$@"
  ) 2>&1 | tee "$log"
  status="${PIPESTATUS[0]}"
  end="$(date -u --iso-8601=seconds)"
  jq -n --arg label "$label" --arg start "$start" --arg end "$end" --argjson status "$status" \
    '{label:$label,started_at:$start,finished_at:$end,exit_code:$status}' > "$RESULT_DIR/${label}.json"
  echo "END $label at $end exit=$status"
  return "$status"
}

record_project() {
  local label="$1" directory="$2"
  cp "$directory/lean-toolchain" "$RESULT_DIR/${label}-lean-toolchain.txt"
  cp "$directory/lake-manifest.json" "$RESULT_DIR/${label}-lake-manifest.json"
  (cd "$directory" && lake --version) > "$RESULT_DIR/${label}-lake-version.txt" 2>&1
}

overall=0
capture_environment

if [[ "$TARGET" = all || "$TARGET" = openai ]]; then
  checkout_exact openai "$OPENAI_URL" "$OPENAI_COMMIT" || exit 1
  openai_dir="$WORK_DIR/openai"
  record_project openai "$openai_dir"
  run_step openai-cache "$openai_dir" lake exe cache get || overall=1
  if [[ "$overall" -eq 0 ]]; then
    run_step openai-build "$openai_dir" lake -j "$BUILD_JOBS" build || overall=1
  fi
  if [[ -f "$RESULT_DIR/openai-build.json" ]] && [[ "$(jq -r .exit_code "$RESULT_DIR/openai-build.json")" -eq 0 ]]; then
    run_step openai-navier-stokes-axioms "$openai_dir" lake env lean NavierStokes/ComparatorSolution.lean || overall=1
    run_step openai-euler-axioms "$openai_dir" lake env lean Euler/Solution.lean || overall=1
  fi
fi

if [[ "$TARGET" = all || "$TARGET" = buckmaster-all || "$TARGET" == buckmaster-* ]]; then
  checkout_exact buckmaster "$BUCKMASTER_URL" "$BUCKMASTER_COMMIT" || exit 1
  case "$TARGET" in
    buckmaster-euler) projects=("euler-blowup") ;;
    buckmaster-boussinesq) projects=("boussinesq-blowup") ;;
    buckmaster-affinecore) projects=("affinecore") ;;
    *) projects=("euler-blowup" "boussinesq-blowup" "affinecore") ;;
  esac
  for project in "${projects[@]}"; do
    project_dir="$WORK_DIR/buckmaster/$project"
    label="buckmaster-${project}"
    record_project "$label" "$project_dir"
    project_ok=0
    run_step "${label}-build" "$project_dir" lake -j "$BUILD_JOBS" build || { overall=1; project_ok=1; }
    if [[ "$project_ok" -eq 0 ]]; then
      run_step "${label}-axioms" "$project_dir" lake env lean scripts/PrintAxioms.lean || overall=1
    fi
  done
fi

echo "utc_finished=$(date -u --iso-8601=seconds)" >> "$RESULT_DIR/environment.txt"
echo "$overall" > "$RESULT_DIR/overall-exit-code.txt"
manifest_tmp="$RESULT_DIR/.SHA256SUMS.tmp"
(cd "$RESULT_DIR" && find . -type f ! -name driver.log ! -name SHA256SUMS ! -name .SHA256SUMS.tmp -print0 | sort -z | xargs -0 sha256sum > "$manifest_tmp")
mv "$manifest_tmp" "$RESULT_DIR/SHA256SUMS"
ln -sfn "$RUN_ID" "$RESULT_ROOT/latest"
echo "results=$RESULT_DIR overall_exit=$overall"
exit "$overall"
