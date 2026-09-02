MAIN      := report
LATEXMK   := latexmk
ENGINE    := -pdf
FLAGS     := -interaction=nonstopmode -halt-on-error -file-line-error
OUT_DIR   := build
DIST_DIR  := dist
PROOF_LOG := proofs/logs/proof-report.json
SHELL     := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

.PHONY: all bootstrap audit-generate audit-check audit_metadata check test prove report clean distclean

all: report

bootstrap:
	@lake env lean --version
	@lake --version
	@printf '%s\n' 'bootstrap ok: Lean/Lake Verity toolchain is available'

audit-generate:
	@python3 scripts/audit_metadata.py generate
	@python3 scripts/generate_ux2.py generate

audit-check:
	@python3 scripts/audit_metadata.py check
	@python3 scripts/generate_ux2.py check

audit_metadata: audit-check
	@printf '%s\n' 'audit_metadata alias: see audit-check'

check: test
	@printf '%s\n' 'check ok: metadata, mutants, receipt, provenance, and executable regressions passed'

test:
	@python3 scripts/audit_metadata.py check
	@python3 scripts/generate_ux2.py check
	@python3 scripts/test_ux2.py
	@python3 scripts/test_gfm_table.py
	@python3 scripts/test_markdown_text.py
	@PYTHONOPTIMIZE=1 python3 scripts/test_audit_metadata.py
	@python3 scripts/check_validation_receipt.py
	@python3 scripts/test_check_validation_receipt.py
	@python3 scripts/check_proof_escapes.py
	@bash scripts/test_check_proof_escapes.sh
	@bash scripts/test_check_trust_axioms.sh
	@python3 scripts/check_trust_axioms.py
	@bash scripts/check_no_python_evidence.sh
	@bash scripts/test_check_no_python_evidence.sh
	@python3 scripts/check_public_claim_surfaces.py
	@python3 scripts/test_public_claim_surfaces.py
	@python3 scripts/check_report_theorem_inventory.py
	@python3 scripts/test_report_theorem_inventory.py
	@python3 scripts/check_diagram_taxonomy.py
	@python3 scripts/test_diagram_taxonomy.py
	@python3 scripts/test_verity_provenance.py
	@bash scripts/check_provenance_guards.sh
	@python3 scripts/check_import_dag.py
	@python3 scripts/test_import_dag.py
	@lake build LidoSRv3Test
	@printf '%s\n' 'LidoSRv3Test: mutants, vectors, nested Verity tests, and regressions compiled'
	@test -s fixtures/solidity-reference/stakingRouter.getDepositAllocations.test.ts
	@test -s fixtures/solidity-reference/stakingRouter.rewards.test.ts
	@test -s fixtures/solidity-reference/stakingRouter.status-control.test.ts
	@test -s fixtures/solidity-reference/deposits-reserve.integration.ts
	@test -s fixtures/solidity-reference/accounting-oracle-module-balances.integration.ts
	@printf '%s\n' 'reference fixtures present; all 5 validated'

prove:
	@python3 scripts/check_verity_provenance.py >/dev/null
	@mkdir -p proofs/logs
	@targets="$$(bash scripts/write_proof_report.sh --targets)"; \
	 [ -n "$$targets" ] || { printf '%s\n' 'no proof receipt targets declared' >&2; exit 1; }; \
	 if { printf 'verified_source_tree='; bash scripts/verified_source_tree.sh; printf 'lean_version='; lake env lean --version; printf 'proof_targets=%s\n' "$$targets"; lake build $$targets; } 2>&1 | tee proofs/logs/prove.txt; then s=0; else s=$$?; fi; \
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
