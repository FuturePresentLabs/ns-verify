# Verification post templates

Publish only after `scripts/check-publish-gates.sh` passes. Replace every `{{PLACEHOLDER}}`; if a step was not run, say so explicitly. Release in order: Lean Zulip, Hacker News, r/accelerate, X. If the build fails, use the failure report first—before commentary, jokes, or speculation.

## Short post: all scheduled checks passed

> Independent recompile report ({{UTC_DATE}}): I checked OpenAI `NavierStokesAndEuler` at `8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538` and Buckmaster `fluid_lean` at `d0124689230b58b4f86e7b90ac59de06404b3b6b` on a fresh DigitalOcean Ubuntu VM ({{CPU}}, {{RAM}}).
>
> PASS: OpenAI `lake exe cache get` + `lake build`.
> PASS: Buckmaster Euler `lake build` + `PrintAxioms.lean`.
> PASS: Buckmaster Boussinesq `lake build` + `PrintAxioms.lean`.
> PASS: Buckmaster AffineCore `lake build Cm24 ChainPlanar AffineCore Challenge Solution` + `PrintAxioms.lean`.
> (AffineCore's lakefile omits the comparator pair from `defaultTargets`; a bare `lake build` exits 0 without compiling `Solution.lean` and its own `PrintAxioms.lean` then fails. Name every declared `lean_lib`.)
>
> Full logs, timings, toolchains, manifests, source bundles, and SHA-256 manifest: {{EVIDENCE_URL}}
>
> Scope: this confirms Lean accepted the pinned formalizations. It does not independently establish that the formal statements faithfully encode the informal PDE/Clay claims. I did not run OpenAI's Comparator replay: {{COMPARATOR_STATUS_OR_REASON}}.

## Short post: partial or failed run

> Independent recompile report ({{UTC_DATE}}), exact commits `8937a8f…` and `d012468…`:
>
> - OpenAI: {{PASS_FAIL_NOT_RUN}} — {{COMMAND_AND_EXIT}}
> - Buckmaster Euler: {{PASS_FAIL_NOT_RUN}} — {{COMMAND_AND_EXIT}}
> - Buckmaster Boussinesq: {{PASS_FAIL_NOT_RUN}} — {{COMMAND_AND_EXIT}}
> - Buckmaster AffineCore: {{PASS_FAIL_NOT_RUN}} — {{COMMAND_AND_EXIT}}
>
> First observed failure: {{PRECISE_FAILURE}}. This is {{KNOWN_TO_BE_PROOF_FAILURE_OR_INFRA_FAILURE_OR_UNKNOWN}}; I am not generalizing it beyond the failed command.
>
> Reproduction bundle and full logs: {{EVIDENCE_URL}}

This failure report has no independent-confirmation gate. Publish it promptly once the logs are safely hosted and personally identifying secrets have been checked; accuracy still outranks speed.

## Long-form verification note

### Claim

On {{UTC_DATE}}, I independently ran the commands below against immutable upstream commits on a newly provisioned VM. The result was {{ONE_SENTENCE_RESULT}}.

### Inputs

- OpenAI repository and commit: `openai/NavierStokesAndEuler@8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538`
- Buckmaster repository and commit: `tristanbuckmaster/fluid_lean@d0124689230b58b4f86e7b90ac59de06404b3b6b`
- Machine: {{DROPLET_PLAN}}, {{CPU}}, {{RAM}}, {{DISK}}, region {{REGION}}
- OS/kernel: {{OS_KERNEL}}
- Runner revision: {{THIS_KIT_COMMIT}}
- Evidence SHA-256: `{{SHA256SUMS_HASH}}`

### Results

| Project | Toolchain | Commands | Exit | Duration | Result |
|---|---|---|---:|---:|---|
| OpenAI | `leanprover/lean4:v4.34.0-rc2` | cache get; build | {{}} | {{}} | {{}} |
| Buckmaster Euler | `leanprover/lean4:v4.32.2` | build; axiom print | {{}} | {{}} | {{}} |
| Buckmaster Boussinesq | `leanprover/lean4:v4.32.2` | build; axiom print | {{}} | {{}} | {{}} |
| Buckmaster AffineCore | `leanprover/lean4:v4.32.2` | build; axiom print | {{}} | {{}} | {{}} |

### Warning and axiom review

{{PASTE_A_CONCISE_SUMMARY_WITH_LOG_FILENAMES_AND_LINE_NUMBERS. Distinguish intentional challenge-file `sorry` warnings from proof-library warnings. Record the exact `PrintAxioms` output.}}

### Interpretation and limits

This is an independent reproducibility check of the pinned Lean artifacts. A successful kernel check is strong evidence that the formal proof term inhabits the formal theorem statement under the reported axioms. It is not, by itself, an audit of the correspondence between that formal statement and the Clay Mathematics Institute's prose, nor a mathematical peer review of definitions and modeling choices. {{LIST_UNRUN_CHECKS, INCLUDING_COMPARATOR}}.

### Reproduce

{{LINK_TO_THIS_KIT_AND_EVIDENCE}}. Provision, run, download, verify `SHA256SUMS`, then destroy the billed VM. No `lake update` is used.
