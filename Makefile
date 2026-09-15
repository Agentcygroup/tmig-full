.PHONY: install verify ci release doctor health probe infra-check infra-status

install:
	@mkdir -p bin
	@for b in xt xt-release; do \
	    [ -x target/release/$$b ] && ln -sf "$$(pwd)/target/release/$$b" "bin/$$b" && echo "  bin/$$b"; \
	done
	@ln -sf "$$(pwd)/ui/cli/tmig" bin/tmig && echo "  bin/tmig"

verify:      ; @scripts/local-verify.sh
ci:          ; @target/release/xt ci
release:     ; @ci/release.sh
doctor:      ; @dxp/doctor.sh
health:      ; @lifecycle/healthcheck.sh
probe:       ; @ix/probe.sh
infra-check: ; @infra/check.sh
infra-status:; @infra/status.sh

go-build:
	@cd "$(CURDIR)" && go build -o bin/tmig-go ./go/cmd/tmig
	@echo "  bin/tmig-go"

go-test:
	@cd "$(CURDIR)" && go vet ./go/... && go test ./go/...
