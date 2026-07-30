MAIN      := report
LATEXMK   := latexmk
ENGINE    := -pdf
FLAGS     := -interaction=nonstopmode -halt-on-error -file-line-error
OUT_DIR   := build
DIST_DIR  := dist
PROOF_LOG := proofs/logs/proof-report.json
SHELL     := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

.PHONY: all bootstrap audit-generate audit-check test prove report clean distclean

all: report

bootstrap:
	@lake env lean --version
	@lake --version
	@printf '%s\n' 'bootstrap ok: Lean/Lake Verity toolchain is available'

audit-generate:
	@python3 scripts/audit_metadata.py generate

audit-check:
	@python3 scripts/audit_metadata.py check

test:
	@python3 scripts/audit_metadata.py check
	@bash scripts/check_no_python_evidence.sh
	@bash scripts/check_provenance_guards.sh
	@lake build LidoSRv3.Audit.Vectors
	@printf '%s\n' 'executable MinFirst falsifier vectors compiled and asserted'
	@test -s tests/solidity-reference/stakingRouter.getDepositAllocations.test.ts
	@test -s tests/solidity-reference/stakingRouter.rewards.test.ts
	@test -s tests/solidity-reference/deposits-reserve.integration.ts
	@printf '%s\n' 'reference fixtures present; no legacy proof artifacts remain'

prove:
	@mkdir -p proofs/logs
	@if { printf 'verified_source_tree='; bash scripts/verified_source_tree.sh; printf 'lean_version='; lake env lean --version; lake build LidoSRv3; } 2>&1 | tee proofs/logs/prove.txt; then s=0; else s=$$?; fi; \
	 if BUILD_STATUS=$$s BUILD_LOG=proofs/logs/prove.txt \
	      bash scripts/write_proof_report.sh > $(PROOF_LOG).tmp; then \
	   mv $(PROOF_LOG).tmp $(PROOF_LOG); \
	   printf '%s\n' 'proof report written to $(PROOF_LOG)'; \
	 else \
	   rm -f $(PROOF_LOG).tmp; \
	   printf '%s\n' 'build did not verify; proof report NOT updated (kept previous $(PROOF_LOG))' >&2; \
	   exit 1; \
	 fi

report: $(DIST_DIR)/lido-srv3-formal-methods-report.pdf

$(OUT_DIR)/$(MAIN).pdf: $(MAIN).tex $(wildcard content/*.tex) $(wildcard style/*.sty)
	@mkdir -p $(OUT_DIR)
	@$(LATEXMK) $(ENGINE) -outdir=$(OUT_DIR) $(FLAGS) $(MAIN).tex \
	  || { rm -f $(OUT_DIR)/$(MAIN).fdb_latexmk; exit 1; }

$(DIST_DIR)/lido-srv3-formal-methods-report.pdf: $(OUT_DIR)/$(MAIN).pdf
	@mkdir -p $(DIST_DIR)
	@cp $(OUT_DIR)/$(MAIN).pdf $(DIST_DIR)/lido-srv3-formal-methods-report.pdf

clean:
	$(LATEXMK) -c -outdir=$(OUT_DIR) $(MAIN).tex || true
	rm -f $(OUT_DIR)/*.aux $(OUT_DIR)/*.log $(OUT_DIR)/*.out \
	      $(OUT_DIR)/*.toc $(OUT_DIR)/*.fls $(OUT_DIR)/*.fdb_latexmk

distclean: clean
	rm -rf $(OUT_DIR) $(DIST_DIR)
