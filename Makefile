SHELL := /bin/bash
TF_BIN ?= $(shell command -v terraform 2>/dev/null || command -v tofu 2>/dev/null)
TF := $(TF_BIN) -chdir=infra
SSH_OPTS := -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30

.PHONY: init fmt validate test plan run apply ready verify status download destroy

init:
	$(TF) init

fmt:
	$(TF_BIN) fmt -recursive -check

validate:
	$(TF) validate

test:
	scripts/test.sh

plan:
	$(TF) plan -out=verify.tfplan

# Preferred entrypoint: cleanup is armed before the Droplet is created.
run:
	scripts/run-ephemeral.sh

# Recovery/debugging only. Prefer `make run` for normal operation.
apply:
	$(TF) apply verify.tfplan

ready:
	ssh $(SSH_OPTS) verifier@$$($(TF) output -raw ipv4_address) 'cloud-init status --wait && test -x /opt/lean-verifier/verify.sh'

verify:
	ssh $(SSH_OPTS) verifier@$$($(TF) output -raw ipv4_address) 'sudo /opt/lean-verifier/verify.sh all'

status:
	ssh $(SSH_OPTS) verifier@$$($(TF) output -raw ipv4_address) 'sudo systemctl status lean-verification --no-pager || true'

download:
	mkdir -p results
	rsync -av --partial -e "ssh $(SSH_OPTS)" verifier@$$($(TF) output -raw ipv4_address):/var/lib/lean-verification/results/ results/

destroy:
	$(TF) destroy -auto-approve
