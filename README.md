# ns-verify — Wagar Machine LLC Continuous Verification Bureau

*A machine shop in Seattle. We don't understand analysis, but a proof checker
doesn't need us to.*

This repo runs **independent Lean kernel verification** of the two 2026
Navier–Stokes / Euler resolution repositories, at pinned upstream commits,
**unmodified**:

| Upstream | Claim | Toolchain |
|---|---|---|
| [`openai/NavierStokesAndEuler`](https://github.com/openai/NavierStokesAndEuler) | Clay alternatives (C)+(D): breakdown for Navier–Stokes at every viscosity; unforced 3D Euler blowup | `lean4:v4.34.0-rc2` |
| [`tristanbuckmaster/fluid_lean`](https://github.com/tristanbuckmaster/fluid_lean) | Finite-time blowup, smooth forcing: 3D Euler, Boussinesq, IPM | `lean4:v4.32.2` |

## Why this is evidence

A Lean build is **binary**: either every proof compiles through Lean 4's
kernel or it does not. We are not mathematicians — that's the point. The
kernel re-checks every proof obligation, including the interval-arithmetic
certificates, so trust flows from the toolchain + [DeepMind's
FormalConjectures](https://github.com/google-deepmind/formal-conjectures)
statement of the Clay problem (used verbatim by the OpenAI repo's comparator),
**not** from anyone's credentials. Ours or theirs.

## Method

1. `git clone` upstream → `git checkout <pinned SHA>` — **zero modifications**
2. `lake build` (all ~10–12k jobs) — the actual verification
3. `#print axioms <headline theorems>` — must report exactly
   `[propext, Classical.choice, Quot.sound]` (the standard Lean trio; any
   `sorryAx` or custom axiom = fail)
4. Verdict + full logs committed to [`results/`](results/) and uploaded as CI artifacts

Run it yourself:

```sh
gh workflow run verify.yml \
  -f repo_url=https://github.com/openai/NavierStokesAndEuler \
  -f pinned_sha=<sha> \
  -f axiom_targets="NavierStokes.Comparator.navier_stokes_breakdown_R3 NavierStokes.Comparator.navier_stokes_breakdown_periodic"
gh run watch   # ~40 min (cache hit) to ~7 h (cold Mathlib)
```

## Results

See [`results/`](results/) — one directory per verification run, containing
`commit.txt`, `provenance.txt`, `build.log`, `axioms.log`, `verdict.txt`.

| Date | Repo | SHA | Verdict |
|---|---|---|---|
| 2026-09-09 | openai/NavierStokesAndEuler | *(pending import)* | ✅ BUILD_OK — 11,251 jobs, 41m57s, axioms = standard trio |
| 2026-09-09 | tristanbuckmaster/fluid_lean | *(in progress)* | ⏳ |

## Scope & honesty

- This verifies **compilations**, not credit claims, not priority disputes.
- The axiom audit verifies the formalization *as written in the pinned repo*
  against the Clay statement *as encoded by DeepMind's FormalConjectures*.
  The kernel→formal-statement→human-statement chain is documented, not divine.
- If a build fails, we publish that immediately and deadpan. First honest
  failure report beats any joke.

## The fine print

*"Wagar Machine LLC"* is a real machine shop that makes real parts. Between
jobs, its CI also checks Millennium Prize problems. The badge is the point:

```yaml
# add to your README:
# [![Wagar Machine Verification Bureau](https://img.shields.io/badge/kernel%20verified-Wagar%20Machine%20LLC-2ea44f)](https://github.com/ajmwagar/ns-verify)
```
