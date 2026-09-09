# Harness: independent Lean fluid-proof verification

Operational documentation for the verification harness in this repository.
For the public summary of results, see the [top-level README](../README.md).

> We don't understand analysis, but a proof checker doesn't need us to.

Reproducible infrastructure, execution, evidence capture, and publication templates for independently compiling:

- OpenAI [`NavierStokesAndEuler`](https://github.com/openai/NavierStokesAndEuler) at `8937a8f4cbc7abaab5e9e97d1cc7f5d2319d9538`.
- Tristan Buckmaster [`fluid_lean`](https://github.com/tristanbuckmaster/fluid_lean) at `d0124689230b58b4f86e7b90ac59de06404b3b6b`.

The pins are inputs, not endorsements. We do not fork or patch either proof repository. The runner clones upstream directly, checks out those exact commits in detached HEAD state, verifies the checkout is clean, uses each project's committed `lean-toolchain` and `lake-manifest.json`, captures full logs and machine metadata, and creates a SHA-256 manifest. It never runs `lake update`. The logs are the deliverable.

## Quick start

Prerequisites: Terraform >= 1.6 (OpenTofu is also supported), a DigitalOcean API token, and an SSH public key. The DigitalOcean provider is pinned to 2.100.0. The default Droplet is memory-optimized with 24 vCPUs, 192 GiB RAM, and 600 GiB local SSD because the largest upstream project recommends roughly 150 GB RAM. DigitalOcean currently lists that class at $1.50/hour; confirm the plan and region before applying.

```sh
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit ssh_public_key and admin_cidr in the copied file.
export DIGITALOCEAN_TOKEN='...'
make run
```

`make run` is the normal entrypoint. It arms a teardown trap before provisioning, runs all checks, downloads and checksum-verifies the evidence, then destroys the Droplet, firewall, and uploaded key even when a build fails or you press Ctrl-C. It retries destruction three times and fails loudly unless Terraform state is empty.

No local guard can execute after the operator machine loses power/network or receives an uncatchable kill. Before starting, set a short external reminder or DigitalOcean billing alert. If the command is interrupted that way, use the control panel immediately or run `make destroy`. The `ephemeral` tag makes recovery resources easy to identify. The separate lifecycle commands are retained for recovery/debugging, not routine use.

## What a green run establishes

A clean `lake build` establishes that Lean accepted the checked-out source with the pinned toolchain and dependencies on this machine. The Buckmaster projects also run their committed `PrintAxioms.lean` checks. It does **not** establish that the formal statements faithfully encode the informal Clay problem, nor does it substitute for mathematical review. OpenAI's optional Comparator replay has extra tools not provisioned here and is deliberately not represented as completed.

Read [the runbook](docs/RUNBOOK.md) before spending money or posting results. Use [the post templates](docs/POSTS.md) only after replacing every placeholder from an actual result bundle.

Publication is deliberately gated. After a run, generate and review the axiom audit, commit it, record either a respected independent confirmation or a completed 72-hour no-refutation window, then run `scripts/check-publish-gates.sh`. The required channel order is Lean Zulip, Hacker News, r/accelerate, then X. If any verification fails, publish the failure report first.
