# Verification runbook

## Scope and acceptance criteria

The unit of reporting is a named project at an exact Git commit. A project passes only when every scheduled command for it exits zero and its evidence files are present.

| Result label | Commands | Important interpretation |
|---|---|---|
| `openai` | `lake exe cache get`; `lake build` | Kernel/type-checker build. Comparator replay is not included. |
| `buckmaster-euler-blowup` | `lake build`; committed `PrintAxioms.lean` | The upstream challenge file intentionally contains a `sorry`; inspect warning location and axiom output. |
| `buckmaster-boussinesq-blowup` | Same | Largest stated memory requirement (~150 GB). |
| `buckmaster-affinecore` | Same | Independent project in the same upstream repository. |

Do not collapse mixed outcomes into “both repositories passed.” A compile checks a formal term against a formal statement; it does not prove the statement matches the English mathematical claim.

## 1. Preflight

1. Review the two pinned commits in `scripts/verify.sh`. Changing a pin creates a different experiment.
2. Install Terraform >= 1.6 and create a scoped DigitalOcean personal access token. Export it as `DIGITALOCEAN_TOKEN`; never put it in a `.tfvars` file.
3. Copy `infra/terraform.tfvars.example` to `infra/terraform.tfvars`. Add your **public** SSH key and your current public IPv4 address as `/32`.
4. Check that `m-24vcpu-192gb` is available in the chosen region: `doctl compute size list` and `doctl compute region list`. If not, select an equivalent with at least 192 GiB RAM and enough local disk.
5. Run `make test`. The guarded command will initialize Terraform and show a plan containing one Droplet, one firewall, and one uploaded public key.
6. Note the current hourly price and set an independent timer/billing alert. The advertised 24-vCPU/192-GiB class was $1.50/hour on 2026-09-08, but pricing changes. This alert is the fallback if the operator machine loses power or network.

## 2. Guarded provision, run, download, and teardown

```sh
make run
```

Use this path for a normal run. Cleanup is armed before `terraform apply`; success, build failure, Ctrl-C, TERM, and HUP all lead through the same teardown routine. It downloads the result bundle and verifies its checksums before normal teardown, retries destroy three times, and confirms that Terraform state is empty.

An uncatchable `kill -9`, local power loss, or prolonged network outage cannot be handled by a local trap. If that occurs, delete resources tagged `ephemeral` in the DigitalOcean control panel or restore connectivity and run `make destroy`. Never assume a powered-off Droplet has stopped billing.

## 3. Recovery/debug execution only

The component commands (`make apply`, `make ready`, `make verify`, `make download`) bypass the all-in-one cleanup guard and are for recovery or debugging only. If you use them, keep `make destroy` ready in another terminal.

Interactive full run after a manual apply:

```sh
make verify
```

Unattended full run (survives SSH disconnect):

```sh
ssh verifier@DROPLET_IP \
  'sudo systemd-run --unit=lean-verification --property=TimeoutStartSec=infinity /opt/lean-verifier/verify.sh all'
ssh verifier@DROPLET_IP \
  'sudo journalctl -u lean-verification -f'
```

Allowed selectors are `all`, `openai`, `buckmaster-all`, `buckmaster-euler`, `buckmaster-boussinesq`, and `buckmaster-affinecore`. Runs are sequential to keep peak memory predictable. A failing project is recorded and later independent projects still run.

Monitor memory, disk, and kernel OOM messages in another terminal:

```sh
ssh verifier@DROPLET_IP 'watch -n 10 free -h'
ssh verifier@DROPLET_IP 'df -h /var/lib/lean-verification; sudo journalctl -k --grep="Out of memory\|Killed process"'
```

## 4. Validate evidence

Download before destroying:

```sh
make download
cd results/latest
sha256sum --check SHA256SUMS
cat overall-exit-code.txt
find . -maxdepth 1 -name '*.json' -print -exec jq . {} \;
```

Then inspect, do not merely count, warnings and axiom reports:

```sh
rg -n "error:|declaration uses 'sorry'|axioms|propext|Classical.choice|Quot.sound" logs/
```

Required publication evidence:

- Exact upstream commit SHA and the repository bundles.
- OS/kernel/CPU/RAM/disk and Lean/Lake/elan versions.
- Every build/check command's UTC start/end, exit code, full stdout/stderr, and `/usr/bin/time -v` data. `driver.log` is live operator output and is excluded from `SHA256SUMS` because it is still open while the manifest is created.
- Committed `lean-toolchain` and `lake-manifest.json` copies.
- `SHA256SUMS`, verified after download.
- A clear list of anything not run, especially Comparator.

## 5. Confirm teardown

`make run` already destroys and verifies empty Terraform state. Confirm independently:

```sh
terraform -chdir=infra state list
# Expected: no output
doctl compute droplet list --tag-name ephemeral
# Expected: no matching verifier Droplet
```

Also confirm the DigitalOcean control panel has no remaining Droplet. If anything remains, run `make destroy`. Terraform state is local and contains infrastructure metadata; keep it private. The uploaded verification SSH-key resource is destroyed with the stack.

## Manual parity

If Terraform is unavailable, create an Ubuntu 24.04 x86-64 Droplet with >=192 GiB RAM, >=400 GiB disk, SSH restricted to your IP, and no inbound services other than SSH. Install the packages listed in `cloud-init.yaml.tftpl`, install elan v4.2.3 as the `verifier` user, copy `scripts/verify.sh` to `/opt/lean-verifier/verify.sh`, and run it as that user. The runner itself performs the exact checkouts and evidence capture; do not run `lake update`.
