# Superseded placeholder

This directory was created as a placeholder before the verification evidence
existed. It previously contained a `verdict.txt` asserting `BUILD_OK` with
`commit.txt` reading `PENDING-IMPORT` — a verdict with no pinned SHA, and a
note claiming a log had been imported when none had been. Both files have been
removed rather than left standing as unsupported claims.

The authoritative OpenAI evidence is
[`../20260909T120225Z`](../20260909T120225Z): all four scheduled steps exit 0,
`overall-exit-code.txt` of `0`, and a `SHA256SUMS` manifest generated on the
verifying machine.

- Pinned commit: `8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538`
- Build: 11,251 jobs, exit 0
- Axioms: all four headline theorems report exactly
  `[propext, Classical.choice, Quot.sound]`
- `sorry` warnings: 4, all in the deliberate `ComparatorChallenges` statement files

The reviewed audit is [`../../audits/20260909T120225Z.md`](../../audits/20260909T120225Z.md).

The earlier figure of `41m57s` came from run `20260909T035008Z`, which was killed
by an infrastructure failure before generating a manifest. The authoritative run
took 1h29m20s because it shared the machine with a concurrent build. Neither
duration is a property of the proofs.
