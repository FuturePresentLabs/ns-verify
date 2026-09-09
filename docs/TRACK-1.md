# Track 1: verification and release protocol

## Non-negotiables

1. No forks and no proof-source modifications. Clone each upstream URL at the pinned SHA into detached HEAD state. The runner records a clean `git status` and bundles that exact commit for reproducibility.
2. The logs are the deliverable. Commentary never outruns the captured commands, exit codes, toolchains, manifests, axiom output, and hashes.
3. A failed run is published before any joke or success claim, in a deadpan factual format. Being the first honest failure report is a valid outcome.
4. A green build alone does not authorize publication.

## Hard publication gates

All three must pass:

- Every scheduled build and axiom command is green, and the downloaded `SHA256SUMS` verifies.
- `scripts/prepare-audit.sh results/RUN_ID` has produced an axiom/warning audit; a human has reviewed it, removed every placeholder, and committed it.
- Either a respected independent party has publicly confirmed the pinned build, or the complete evidence has been public for at least 72 hours without a substantive refutation. The evidence record is committed under `confirmations/`.

Run the executable gate immediately before drafting a success post:

```sh
scripts/check-publish-gates.sh results/RUN_ID confirmations/RECORD.md
```

If it does not print `PUBLICATION GATES PASS`, do not publish a success claim.

## Release order

Do not cross-post simultaneously. Preserve this order:

1. Lean Zulip — technical report, exact commands, logs, axiom audit, limitations; invite reproduction.
2. Hacker News — link to the Zulip report and evidence after the credibility anchor exists.
3. r/accelerate — the victory lap, still linked to the primary evidence.
4. X — concise amplification linking back to the durable report.

Record URLs and UTC timestamps in the eventual publication ledger. Corrections propagate forward through every later channel.

## Voice

The README line is: “We don't understand analysis, but a proof checker doesn't need us to.” The joke is epistemic humility, not overclaiming. Every post distinguishes kernel acceptance from statement fidelity and peer review.

