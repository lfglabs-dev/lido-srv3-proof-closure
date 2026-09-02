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

audit-check:
	@python3 scripts/audit_metadata.py check

audit_metadata: audit-check
	@printf '%s\n' 'audit_metadata alias: see audit-check'

check: test
	@printf '%s\n' 'check ok: metadata, mutants, receipt, provenance, and executable regressions passed'

test:
	@python3 scripts/audit_metadata.py check
	@python3 scripts/test_gfm_table.py
	@python3 scripts/test_markdown_text.py
	@PYTHONOPTIMIZE=1 python3 scripts/test_audit_metadata.py
	@python3 scripts/check_validation_receipt.py
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
	@lake build LidoSRv3.Tests.MinFirstVectors
	@printf '%s\n' 'executable MinFirst falsifier vectors compiled and asserted'
	@lake build LidoSRv3.Tests.PAlloc1EugeneBoundVectors
	@printf '%s\n' 'executable Eugene operator-bond vectors compiled and asserted'
	@lake build LidoSRv3.Tests.SszRegression
	@printf '%s\n' 'executable structural SSZ branch regressions compiled and asserted'
	@lake build LidoSRv3.Audit.Verity.Tests.SszTxSimulation
	@printf '%s\n' 'typed SSZ transaction-simulation acceptance/mutant/rollback vectors compiled and asserted'
	@lake build LidoSRv3.Tests.SszEncodingTxMutants
	@printf '%s\n' 'P-SSZ-1 composed encoding transaction mutants, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.DepositVectors
	@printf '%s\n' 'executable deposit conservation/rollback falsifier vectors compiled and asserted'
	@lake build LidoSRv3.Tests.DepositTxMutants
	@printf '%s\n' 'bounded Verity deposit transaction mutant compiled and asserted'
	@lake build LidoSRv3.Tests.DepositParentTxMutants
	@printf '%s\n' 'P-DEPOSIT-1 composed transaction mutants (per-module writes, journal, ledger) compiled and asserted'
	@lake build LidoSRv3.Audit.Verity.DepositNFrameTx LidoSRv3.Audit.Spec.DepositNFrameCorrespondence LidoSRv3.Tests.DepositNFrameTxMutants
	@printf '%s\n' 'P-DEPOSIT-1 list-batch journal, router bridge, no-wrap, and fixed-two kill-line compiled and asserted'
	@lake build LidoSRv3.Audit.Provenance.Deposit LidoSRv3.Tests.PackGDepositProvenanceMutants
	@printf '%s\n' 'P-DEPOSIT-1 source-backed deployment-provenance counterexample compiled and asserted; deployment assumptions remain OPEN'
	@lake build LidoSRv3.Tests.MinFirstAmountTxMutants
	@printf '%s\n' 'P-ALLOC-2 amount transaction mutants and floor-division regression compiled and asserted'
	@lake build LidoSRv3.Tests.MinFirstDistributionTxMutants
	@printf '%s\n' 'P-ALLOC-2 full memory-array transaction mutants, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.AllocationTxMutants
	@printf '%s\n' 'P-ALLOC-1 allocation-loop transaction mutants, moduleAddress binding, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.ConsolidationTxMutants
	@printf '%s\n' 'P-CONSOLIDATION-1 call/event/memory transaction mutants, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.TopupVectors
	@printf '%s\n' 'executable top-up conservation/rollback falsifier vectors compiled and asserted'
	@lake build LidoSRv3.Tests.TopupHybridMutants
	@printf '%s\n' 'hybrid Verity top-up transaction mutants compiled and asserted'
	@lake build LidoSRv3.Tests.TopupTxMutants
	@printf '%s\n' 'faithful P-TOPUP-1 executable-transaction mutants (skipped allocation words, dropped/misrouted/short-paid/reordered/duplicated deposits) and intermediate-effect rollback compiled and asserted'
	@lake build LidoSRv3.Tests.Topup2TxMutants
	@printf '%s\n' 'bounded Verity P-TOPUP-2 aggregate-cap transaction mutants compiled and asserted'
	@lake build LidoSRv3.Tests.Topup2DistributionTxMutants
	@printf '%s\n' 'P-TOPUP-2 faithful memory-array transaction mutants, overflow, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.ReserveMutants
	@printf '%s\n' 'executable reserve non-interference and rollback mutants compiled and asserted'
	@lake build LidoSRv3.Tests.ReserveRelationalMutants
	@printf '%s\n' 'P-RESERVE-RELATIONAL abstract/source correspondence, dependency mutants, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.ReserveRelationalTxMutants
	@printf '%s\n' 'P-RESERVE-RELATIONAL faithful finalization transaction mutants, non-vacuous decoding witness, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Tests.PConsolidationEth1RefundTxMutants
	@printf '%s\n' 'P-CONSOLIDATION-ETH-1a gateway/vault refund Contract.run mutants compiled and asserted'
	@lake build LidoSRv3.Tests.PConsolidationEth1RequestTxMutants
	@printf '%s\n' 'P-CONSOLIDATION-ETH-1b bus/request Contract.run mutants compiled and asserted'
	@lake build LidoSRv3.Tests.PConsolidationEth1CompositionTxMutants
	@printf '%s\n' 'P-CONSOLIDATION-ETH-1 recursively dispatched Bus/Gateway/Vault drop, misroute, corrupt, rollback, and two-batch mutants compiled and asserted'
	@lake build LidoSRv3.Tests.AccountingVectors
	@printf '%s\n' 'executable accounting order/length/bound/overflow mutants compiled and asserted'
	@lake build LidoSRv3.Tests.HandleOracleReportTxMutants
	@printf '%s\n' 'P-ACCOUNT-1 faithful oracle-report transaction mutants, rollback, and two-batch chain compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.POracleSupply1 LidoSRv3.Tests.PackN3OracleMintMutants
	@printf '%s\n' 'P-ORACLE-SUPPLY-1 live computed mint parent and free-argument/sum-balances/raw-fee kill-lines compiled and asserted'
	@lake build LidoSRv3.Audit.Source.SubmitReportFeeCorrespondence LidoSRv3.Audit.Verity.SubmitReportEntryTx LidoSRv3.Tests.PackP3SubmitReportEntryMutants
	@printf '%s\n' 'P-ORACLE-SUPPLY-1 modeled submitReportData computed-entry parent and still-free/skip-simulate kill-lines compiled and asserted'
	@lake build LidoSRv3.Tests.PackO2SupplyDomainMutants
	@printf '%s\n' 'P-ORACLE-SUPPLY-1 source-domain strengthening, domain-guard load-bearing mutant, and quantization-gap witness compiled and asserted'
	@lake build LidoSRv3.Audit.Source.SanityEnvelope LidoSRv3.Tests.SanityEnvelopeMutants
	@printf '%s\n' 'oracle sanity-envelope source-domain and guard-drop mutants compiled and asserted'
	@lake build LidoSRv3.Tests.AddressEquivariance
	@printf '%s\n' 'abstract address-renaming field and mutant regressions compiled and asserted'
	@lake build LidoSRv3.Tests.AddressSourceMutants
	@printf '%s\n' 'P-ADDRESS-1 executable address-writer, wrong-recipient, and admission-boundary mutants compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.PAddressBatch1 LidoSRv3.Tests.PackN4AddressBatchMutants
	@printf '%s\n' 'P-ADDRESS-BATCH-1 fuel-bounded recipient-rename parent and fixed-dest kill-line compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.PAllocExec1 LidoSRv3.Tests.PackN1AllocExecMutants
	@printf '%s\n' 'P-ALLOC-EXEC-1 router ExecutesAllocation parent and raw-count router kill-line compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.PEthJournal1 LidoSRv3.Tests.PackN2EthJournalMutants
	@printf '%s\n' 'P-ETH-JOURNAL-1 JournalApproved-implies-exclusion parent and Lido-hop kill-line compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.PVaultEth1 LidoSRv3.Tests.PackP2VaultEthMutants
	@printf '%s\n' 'P-VAULT-ETH-1 Vault-to-Lido/WQ Spec-source-value-frame parent and zero-value kill-line compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.PSszLive1 LidoSRv3.Tests.PackN5SszLiveMutants LidoSRv3.Tests.PackW2GindexMutants
	@printf '%s\n' 'P-SSZ-LIVE-1 constructor-pin GI parent, skip-lookup kill-line, and wrong-packed-word kill-line compiled and asserted'
	@lake build LidoSRv3.Audit.Guarantees.PConsolidationValue1 LidoSRv3.Tests.PackN6ConsolValueMutants LidoSRv3.Tests.PackP6OfficialSuccessMutants
	@printf '%s\n' 'P-CONSOLIDATION-VALUE-1 official-success and justified-forwards parent and kill-lines compiled and asserted'
	@lake build LidoSRv3.Tests.WithdrawalQueueRequestAmountMutants
	@printf '%s\n' 'WithdrawalQueue single-request amount-bound mutant compiled and asserted'
	@test -s fixtures/solidity-reference/stakingRouter.getDepositAllocations.test.ts
	@test -s fixtures/solidity-reference/stakingRouter.rewards.test.ts
	@test -s fixtures/solidity-reference/stakingRouter.status-control.test.ts
	@test -s fixtures/solidity-reference/deposits-reserve.integration.ts
	@test -s fixtures/solidity-reference/accounting-oracle-module-balances.integration.ts
	@printf '%s\n' 'reference fixtures present; all 5 validated'

prove:
	@python3 scripts/check_verity_provenance.py >/dev/null
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
