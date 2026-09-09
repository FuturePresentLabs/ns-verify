# Result bundles

Each bundle is one invocation of `scripts/verify.sh` on a freshly provisioned
DigitalOcean droplet (16 vCPU / 128 GiB, sfo3, Ubuntu 24.04). A bundle contains
the raw logs, per-step exit codes with UTC timestamps, toolchain and lake
manifests, `lscpu`/`lsblk`/environment capture, a git bundle of each upstream
repository at its pinned commit, and a `SHA256SUMS` manifest generated on the
machine that produced it.

`SHA256SUMS` deliberately excludes `driver.log`, which is the driver's own
combined transcript and is still being written when the manifest is generated.
`driver.log` therefore cannot be integrity-checked from the manifest.

## Authoritative bundles

These two carry the verification. Together they cover all ten required steps
with exit 0, and each has `overall-exit-code.txt` of `0` and a manifest that
verifies.

| Bundle | Covers | Steps |
|---|---|---|
| `20260909T120225Z` | OpenAI `NavierStokesAndEuler` @ `8937a8f4` | cache, build, 2 axiom audits |
| `20260909T153241Z` | Buckmaster `fluid_lean` @ `d0124689` | build + axiom audit for euler-blowup, boussinesq-blowup, affinecore |

Reviewed audits for both are in [`../audits/`](../audits/).

## Incident record

These two are preserved because the logs are the deliverable and a failed run
is reported, not discarded. Neither is used to support any claim.

| Bundle | Outcome |
|---|---|
| `20260909T035008Z` | Driver killed mid-run by `SIGPIPE` (exit 141). No `overall-exit-code.txt`, no manifest. |
| `20260909T114443Z` | `overall-exit-code.txt` = 1: `buckmaster-affinecore-axioms` failed. |

`20260909T035008Z` additionally contains `LOCAL-SHA256SUMS`. That file was **not**
produced by the verifier. It was computed on the operator's machine after the
bundle was downloaded, because the run died before generating its own manifest.
It establishes only that these files are unchanged since download; it is not
machine-generated integrity evidence and is not used to support any claim.

The source bundles are byte-identical across all runs (one `sha256` for
`fluid_lean`, one for `NavierStokesAndEuler`), so the pinned upstream source is
verifiably the same in every bundle here.

### What happened

The run driver routes all output through `exec > >(tee -a driver.log)`, and that
`tee` also wrote to the SSH channel of the orchestrating process. That process
exited while the build was running. The socket survived on TCP keepalive for
2h22m — logs freeze at 09:07 UTC while `.olean` files kept being written until
11:29 UTC — then errored. `tee` took `SIGPIPE`, `pipefail` turned the broken pipe
into a failed build step, and the next write killed the driver before it could
write `overall-exit-code.txt` or the manifest. Zero proof errors occurred in
10,115 jobs. The failure was in the logging path, not the mathematics.

`20260909T114443Z` then failed its affinecore axiom audit with
`unknown module prefix 'Solution'`. affinecore's lakefile sets
`defaultTargets = ["AffineCore"]` and omits the comparator pair, so a bare
`lake build` exits 0 without ever compiling `Solution.lean` — the file binding
`forced_boussinesq_affine_core_blowup` to its proof — while the project's own
`scripts/PrintAxioms.lean` imports it. **Anyone reproducing this repository with
a bare `lake build` on affinecore gets a green build that verifies less than it
appears to.** The harness now names every `lean_lib` a project declares.

Two earlier aborted runs (`20260909T033937Z`, `20260909T034431Z`) failed during
provisioning before any verification step executed. They contain no build or
axiom results and are not published.
