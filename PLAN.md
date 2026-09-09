# Wagar Machine LLC — Verification & Simulation Plan

*Drafted 2026-09-09. Two tracks that share one artifact: an independent Lean verification
of the week's Navier–Stokes / Euler results, and the product thesis it demonstrates.*

---

## Context (the week that was)

- **Sept 7** — Alpöge (Anthropic) & Buckmaster (NYU) publish Lean-verified finite-time blowup
  for forced 3D Euler (+IPM, Boussinesq), built on Córdoba–Martínez-Zoroa. Repo:
  `tristanbuckmaster/fluid_lean` (3,748 files, Lean 4.32.2).
- **Sept 8** — OpenAI claims Clay alternatives (C)+(D) for Navier–Stokes at all viscosities,
  plus **unforced** Euler blowup, via ~10k-agent swarm. Repo:
  `openai/NavierStokesAndEuler` (2,486 files, Lean 4.34.0-rc2).
- The two camps tell contradictory stories about credit and pressure. The math, however,
  is binary: Lean compiles or it doesn't.
- **Local audit (Sept 8):** both repos show 0 `axiom` decls, 0 `native_decide`, 0 `Float`
  (exact ℚ / fixed-point interval arithmetic throughout). Sorries only in deliberate
  challenge/comparator files.

---

## Track 1 — Independent verification ("the shitpost that's also correct")

### Principle
**No forks. Clone upstream at a pinned SHA and never touch a byte.** A third-party build log
of their exact commit is stronger evidence than any fork — it can't be accused of tampering.

### Repo design — `wagar-machine/ns-verify` (public)

```
ns-verify/
├── README.md                 # "Wagar Machine LLC Continuous Verification Bureau"
├── .github/workflows/verify.yml
└── results/                  # committed logs per run: SHA, toolchain, verdict
```

**Workflow core steps:**
1. Provenance block (runner, UTC timestamps, verifier identity).
2. Install elan → toolchain from repo's `lean-toolchain`.
3. `git clone` upstream → `git checkout <pinned_sha>` → record `rev-parse HEAD`.
4. `lake exe cache get` (Mathlib cache) → `lake build` (the actual verification).
5. **Axiom audit:** small file importing the proof root with `#print axioms` for the
   headline theorems. Expected: `proofs rely on: standard axioms only` (propext,
   Classical.choice, Quot.sound — Mathlib-normal, no custom axioms).
6. Verdict file + artifact upload (build.log, axioms.log, commit.txt).

**Hardware:** GitHub public runners (4 vCPU / 16 GB) likely suffice; fallback cloud VM
(8–16 vCPU, 32–64 GB, spot). Expect 2–7 h; Mathlib cache avoids the day-long Mathlib build.
Risk: a few `decide +kernel` certificate files are multi-MB and memory-hungry.

**Targets to verify (both repos):**
| Repo | SHA | Headline constants |
|---|---|---|
| `openai/NavierStokesAndEuler` | pin at run time | `navier_stokes_breakdown_R3`, `navier_stokes_breakdown_periodic` |
| `tristanbuckmaster/fluid_lean` | pin at run time | Euler/IPM/Boussinesq blowup theorems (root: `EulerBlowup.Num.Cert.FinalPrime`) |

### README voice (draft)
> Machine shop in Seattle. We don't understand analysis, but a proof checker doesn't
> need us to. This repo runs the two 2026 Navier–Stokes / Euler resolution repositories
> through Lean 4's kernel on third-party CI, at pinned commits, unmodified. Trust the
> kernel, not the credentials — ours or theirs. Badge below. Logs in `results/`.

### Posting sequence (in order, one anchor at a time)
1. **Lean Zulip** (formalization stream) — deadpan, zero jokes: "Independent build of
   `openai/NavierStokesAndEuler` @ `<sha>`: clean, 4 vCPU CI, log: <link>." This is the
   credibility anchor. Useful, not trollish.
2. **HN** — top-level comment on the live 430-pt thread: pinned SHA + repo link.
   One dry joke maximum.
3. **r/accelerate** — the victory lap: "Local machine shop resolves 90-year-old open
   problem between jobs."
4. **X** — screenshot of the green badge. "Machine shop CI: ✅"

### Timing gates (all must pass before ANY post)
- [ ] Our build finishes green on the pinned SHA
- [ ] Axiom audit output committed
- [ ] At least one respected community member independently confirms (Zulip/Mastodon),
      or 72 h pass with no refutation
- [ ] Repo README + badge finalized

### Rules of engagement
- Post **nothing** during the OpenAI/Buckmaster he-said-she-said cycle. The verification
  is the one neutral fact in the circus — it stays above the fight.
- If the build **fails**: publish that too, immediately, factually. Being the first
  honest failure report is worth more than the joke.
- Never editorialize about who deserves credit.

---

## Track 2 — The business: proof-carrying simulation

### Thesis
The transferable asset this week isn't the theorems — it's the **method**:
LLM agents + certified (interval) arithmetic + optional Lean = machine-checked
engineering math at swarm speed. Industrial CFD/FEA ships convergence guesses;
nobody ships certificates. A machine shop that *makes the parts it verifies* is the
one vendor whose margins carry consequences.

### Product ladder

| # | Product | What it is | Market | Effort |
|---|---|---|---|---|
| 2 | **Singular benchmark suite** | Blowup constructions as analytic near-singular reference solutions; convergence-order torture tests for solver vendors (Ansys, Siemens) + academia | Small, high-credibility, zero competition | Low — extract from papers, run comparisons. **Rides this week's news** |
| 1 | **Certified FEA margins** | Gmsh/OCCT mesh → a posteriori error bounds in outward-rounded interval arithmetic → stress margins as provable `[lo, hi]`, not a contour plot | Aerospace, medical, pressure vessels — anywhere sign-off happens | Medium — certified a posteriori FEM is established academic math (Patera, Ladevèze), never productized |
| 3 | **Agent-swarm verification reports** | This week's verification, productized: swarm + certified numerics against a client's hardest check (fit/clearance chains, thermal margins, GD&T stack-ups) | Fundable *now* while the world watches AI do Millennium problems | Medium |
| 4 | **Design codes in Lean** | ASME BPVC VIII / Eurocode checks formalized; kernel-verified calc packages | Consulting gold rush; boring moat once built | High, incremental |

### Wedge
**#2 → #1.** The benchmark suite buys attention for free; certified margins is the
durable product. Positioning line nobody else on earth can put in a quote:

> **"Provably conservative margins, from the shop that machines the parts."**

### What we explicitly do NOT do
- No from-scratch CFD solver. The moat is verification + certificates, not
  competing with Siemens on solvers.
- No Lean-first approach to Track 2's core (interval arithmetic is the engine;
  Lean is the garnish for marketing and the codes-formalization niche).

### 90-day sketch
- **Days 0–7:** verification repo live + posts land (Track 1).
- **Weeks 2–6:** extract benchmark problems from the two papers; run Taylor-Green
  vs. near-singular comparisons in our existing toolchain; write the one-pager.
- **Weeks 6–12:** prototype certified-margin pipeline on ONE part family we already
  machine (pick something with real sign-off pain — pressure vessel or fixture);
  demo to 3 target accounts.

---

## Risks & honesty ledger

- **The proofs could fail compilation.** Handle: we publish failure honestly (Track 1
  rule). Track 2's thesis survives either way — the *method* demo is the point.
- **Someone big verifies first.** Fine: we lose the scoop, keep the artifact + the
  "machine shop did it on CI" angle. Never rush to beat a serious verifier.
- **Scope creep into solver-land.** Guarded by the "do NOT do" list.
- **Brand tied to a disputed result.** The repo verifies *compilations*, not credit
  claims. README says so explicitly.

## Immediate next actions
- [ ] Create public repo `wagar-machine/ns-verify`, push workflow + README
- [ ] First CI run against `openai/NavierStokesAndEuler` pinned SHA
- [ ] Parallel run against `tristanbuckmaster/fluid_lean`
- [ ] Commit logs to `results/`, finalize badge
- [ ] Draft Zulip post (Zulip-first sequencing, per above)
- [ ] Bookkeeping decision: which entity/repo name carries the business branding
