# Live verification run handoff

Updated: 2026-09-09 (America/Los_Angeles)

This file is operational context for the currently running verification. It contains no credentials.

## Non-negotiable constraints

- Clone upstream repositories directly at the pinned SHAs and do not modify their trees.
- The raw logs are the primary deliverable. Do not filter or rewrite them.
- Do not interrupt a CPU-active Lean process merely because it is quiet; some files have taken 20–39 minutes.
- Before ending, retrieve and checksum the evidence bundle, then confirm that the Droplet, firewall, and temporary SSH key were destroyed and that the local OpenTofu/Terraform state is empty.
- Do not publish externally yet. Publication requires a green build, committed axiom audit, and either a respected independent confirmation or 72 hours without refutation.
- If a proof build fails, record and publish the failure honestly before any celebratory post.
- Intended publication repository: `FuturePresentLabs/ns-verify`.
- Intended post order: Lean Zulip, Hacker News, r/accelerate, X.

## Live orchestration

- Local workspace: `/Users/ajmwagar/src/math`
- Foreground unified-exec session ID: `68643`
- Run ID: `20260909T035008Z`
- Evidence destination after download: `results/20260909T035008Z`
- DigitalOcean Droplet ID: `598929117`
- Droplet IP: `64.23.142.33`
- Region/size: `sfo3`, `m-16vcpu-128gb`
- The DigitalOcean token is available to the already-running guarded shell and is also stored locally in the gitignored `.env` file at the workspace root. It must never be committed or copied into logs. Revoke it after teardown, then delete the local `.env` file.

The `make run` wrapper armed its cleanup trap before provisioning. It will download/check the evidence and destroy the Droplet, firewall, and temporary SSH key on normal completion, failure, or ordinary signals. Laptop death, network loss, and `kill -9` cannot execute a local trap, so final DigitalOcean confirmation is mandatory.

## How to monitor

Poll the foreground session without writing input:

```text
write_stdin(session_id=68643, chars="", yield_time_ms=60000)
```

If the wrapper reports a running tool cell, wait on that cell before issuing another poll. Never send Ctrl-C unless teardown is deliberately required.

Optional read-only telemetry (does not alter the build):

```sh
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
  root@64.23.142.33 \
  'ps -C lean -o pid,etime,%cpu,%mem,rss,stat,cmd --sort=-rss | head -8; free -h; swapon --show; df -h /'
```

## Completed in this run

### OpenAI NavierStokesAndEuler

- Upstream: `https://github.com/openai/NavierStokesAndEuler.git`
- Pinned commit: `8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538`
- Lean: `v4.34.0-rc2`
- `lake exe cache get`: success
- Exact `lake build`: success, 11,251 jobs, about 41m57s
- Explicit axiom checks: success
- Audited theorem dependencies: only `propext`, `Classical.choice`, `Quot.sound`
- Four `sorry` warnings occurred only in the deliberate statement-side `ComparatorChallenges` files and are preserved in the log.

### Buckmaster fluid_lean / euler-blowup

- Upstream: `https://github.com/tristanbuckmaster/fluid_lean.git`
- Pinned commit: `d0124689230b58b4f86e7b90ac59de06404b3b6b`
- Lean: `v4.32.2`
- Exact `lake build`: success, all 9,776 jobs, exit 0
- `EulerBlowup.Theorem01` and `EulerBlowup.Theorem01Prime`: compiled successfully
- Explicit axiom audit: success, exit 0
- `euler_smooth_force_blowup` and `EulerBlowup.Num.Cert.theorem01prime` depend only on `propext`, `Classical.choice`, `Quot.sound`
- Ordinary linter/deprecation warnings are numerous and preserved verbatim.

## Current phase

Buckmaster `boussinesq-blowup` is building from source in its independent project tree. At the time of this update it was approximately 4,088/10,115 jobs, with no failures or resource pressure. After it finishes, the runner should execute its axiom audit and then build/audit `affinecore`.

## Completion checklist

1. Observe each remaining build and axiom-audit exit status; do not infer success from intermediate theorem messages.
2. Let the wrapper create the evidence bundle and SHA-256 manifest.
3. Confirm the bundle was copied to `results/20260909T035008Z` and validate its manifest locally.
4. Observe cleanup retries and the explicit empty-state confirmation.
5. Independently verify through DigitalOcean API/state that Droplet `598929117`, its firewall, and temporary SSH key no longer exist.
6. Run `scripts/prepare-audit.sh results/20260909T035008Z`, review every generated claim against logs, and commit the audit only if accurate.
7. Keep publication gates closed until the independent-confirmation/72-hour condition is satisfied.
8. Tell the user to revoke the exposed DigitalOcean token after teardown.
