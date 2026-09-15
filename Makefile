.PHONY: verify infra-bootstrap infra-status infra-reconcile infra-check

verify:      ; @scripts/local-verify.sh
infra-check: ; @infra/check.sh
infra-bootstrap: ; @infra/bootstrap.sh
infra-status:    ; @infra/status.sh
infra-reconcile: ; @infra/bin/reconcile
