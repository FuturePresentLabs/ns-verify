# ns-verify — Future Present Labs Continuous Verification Bureau

[![verify-evidence](https://github.com/FuturePresentLabs/ns-verify/actions/workflows/verify-evidence.yml/badge.svg)](https://github.com/FuturePresentLabs/ns-verify/actions/workflows/verify-evidence.yml)

*Future Present Labs LLC — a machine shop in Seattle. We don't understand
analysis, but a proof checker doesn't need us to.*

This repository runs **independent Lean kernel verification** of the two 2026
Navier–Stokes / Euler resolution repositories, at pinned upstream commits,
**unmodified**:

| Upstream | Claim | Toolchain |
|---|---|---|
| [`openai/NavierStokesAndEuler`](https://github.com/openai/NavierStokesAndEuler) | Clay alternatives (C)+(D): breakdown for Navier–Stokes at every viscosity; unforced 3D Euler blowup | `lean4:v4.34.0-rc2` |
| [`tristanbuckmaster/fluid_lean`](https://github.com/tristanbuckmaster/fluid_lean) | Finite-time blowup, smooth forcing: 3D Euler, Boussinesq, IPM | `lean4:v4.32.2` |

## Why this is evidence

A Lean build is **binary**: either every proof compiles through Lean 4's
kernel, or it does not. We are machinists, not mathematicians — that's the
point. The kernel re-checks every proof obligation, including the
interval-arithmetic certificates, so trust flows from the toolchain and from
[DeepMind's FormalConjectures](https://github.com/google-deepmind/formal-conjectures)
statement of the Clay problem (used verbatim by the OpenAI repo's comparator) —
**not** from anyone's credentials. Ours or theirs.

## Method

1. `git clone` upstream → `git checkout <pinned SHA>` — **zero modifications**
2. `lake build` (all ~10–12k jobs) — the actual verification
3. `#print axioms <headline theorems>` — must report exactly
   `[propext, Classical.choice, Quot.sound]` (the standard Lean trio; any
   `sorryAx` or custom axiom = fail)
4. Verdict + full logs committed to [`results/`](results/), with a `SHA256SUMS`
   manifest generated on the verifying machine

A caveat learned the hard way, in step 2: `lake build` builds a project's
*default* targets. `affinecore` leaves its comparator pair out of
`defaultTargets`, so a bare `lake build` there exits 0 **without ever compiling
`Solution.lean`** — the file binding `forced_boussinesq_affine_core_blowup` to
its proof — and the project's own `scripts/PrintAxioms.lean` then fails with
`unknown module prefix 'Solution'`. The harness now names every `lean_lib` a
project declares. Anyone verifying that repository with a bare `lake build`
gets a green build that establishes less than it appears to.

Run it yourself — this provisions an ephemeral droplet, runs the verification,
downloads the evidence, and destroys the infrastructure:

```sh
cp infra/terraform.tfvars.example infra/terraform.tfvars   # add your SSH key + /32
export DIGITALOCEAN_TOKEN=...
make run
```

Read [the runbook](docs/RUNBOOK.md) first; it covers cost, teardown
verification, and the publication gates. [`docs/HARNESS.md`](docs/HARNESS.md)
documents the harness itself.

## Results

See [`results/`](results/) — one directory per run, each containing the raw
logs, per-step exit codes with UTC timestamps, toolchain and lake manifests,
machine capture, a git bundle of the upstream source at its pinned commit, and
a `SHA256SUMS` manifest generated on the machine that produced it.
[`results/README.md`](results/README.md) distinguishes the authoritative
bundles from runs preserved as an incident record.

| Date | Repo | Pinned SHA | Verdict |
|---|---|---|---|
| 2026-09-09 | openai/NavierStokesAndEuler | [`8937a8f`](https://github.com/openai/NavierStokesAndEuler/commit/8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538) | ✅ BUILD_OK — 11,251 jobs, exit 0, axioms = standard trio |
| 2026-09-09 | tristanbuckmaster/fluid_lean | [`d012468`](https://github.com/tristanbuckmaster/fluid_lean/commit/d0124689230b58b4f86e7b90ac59de06404b3b6b) | ✅ BUILD_OK — euler-blowup, boussinesq-blowup, affinecore; all exit 0, axioms = standard trio |

Evidence: [`results/20260909T120225Z`](results/20260909T120225Z) (OpenAI) and
[`results/20260909T153241Z`](results/20260909T153241Z) (Buckmaster). Reviewed
axiom audits for both are in [`audits/`](audits/).

All ten scheduled steps exited 0. Ten audited theorems report exactly
`[propext, Classical.choice, Quot.sound]`; no `sorryAx` appears in any axiom
output. Seven `declaration uses \`sorry\`` warnings occur, all in statement-side
challenge files (four in OpenAI's `ComparatorChallenges`, three in the
Buckmaster projects' `Challenge.lean`), and none reaches an audited theorem.

Build durations are not comparable across runs: the OpenAI build took 41m57s
running alone and 1h29m20s in the authoritative bundle, where it shared 16
cores with a concurrent Buckmaster build.

## What CI does

[`verify-evidence.yml`](.github/workflows/verify-evidence.yml) runs on every push
and daily. It **does not re-run the proofs** — GitHub-hosted runners are 4 vCPU /
16 GiB RAM / 14 GiB disk with a 6-hour cap, while this verification peaked at
~33 GiB resident and ~70 GiB of disk over several hours on a 16 vCPU / 128 GiB
machine.

What it re-checks, via [`scripts/check-evidence.sh`](scripts/check-evidence.sh):
manifests generated on the verifying machine still verify, every recorded step
exited 0, every audited theorem reports exactly the standard trio, no `sorryAx`
appears, each bundle carries a reviewed audit with no placeholders, and the
bundles together cover all ten required steps. A green badge means the published
evidence is intact and internally consistent — it does not mean a runner
recompiled Mathlib.

Reproducing the actual verification takes a real machine: see `make run` and
[the runbook](docs/RUNBOOK.md).

## Scope & honesty

- This verifies **compilations**, not credit claims, not priority disputes.
- The axiom audit verifies the formalization *as written in the pinned repo*
  against the Clay statement *as encoded by DeepMind's FormalConjectures*.
  The kernel → formal-statement → human-statement chain is documented, not divine.
- If a build fails, we publish that immediately and without commentary.
  An honest failure report is worth more than a clean joke. Two runs from
  2026-09-09 failed and are published in [`results/`](results/) alongside the
  successful ones; both failures were in our harness, never in the proofs.
- The Buckmaster bundle was produced in `resume` mode, reusing build artifacts
  from an interrupted earlier run after asserting the tree sat at the exact
  pinned commit with a clean working tree. The audit records this.

## Verification, not certification-for-hire (yet)

Future Present Labs machines parts. The same discipline behind this repo —
provably conservative margins from the shop that machines the parts — is the
product thesis of our certified-simulation work. If you need stress margins
that come with proofs instead of contour plots, that's the direction.

## The fine print

*Future Present Labs LLC* is a real machine shop that makes real parts.
Between jobs, it also runs a Lean kernel over Millennium Prize problems and
publishes the logs.

If you want to point at a verification, point at the evidence rather than at
us — a badge that links to a specific pinned commit and its axiom audit is worth
something; one that links to a vendor is not:

```markdown
[![kernel verified](https://img.shields.io/badge/kernel%20verified-8937a8f-2ea44f)](https://github.com/FuturePresentLabs/ns-verify/blob/main/audits/20260909T120225Z.md)
```

Scope, as always: that badge asserts Lean accepted the pinned source with the
pinned toolchain and that the axiom audit passed. It asserts nothing about
whether the formal statement encodes the informal claim.
