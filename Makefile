MAIN      := report
LATEXMK   := latexmk
ENGINE    := -pdf
FLAGS     := -interaction=nonstopmode -halt-on-error -file-line-error
OUT_DIR   := build
DIST_DIR  := dist
PYTHON    := python3
PYTHONPATH := verity/src
PROOF_LOG := proofs/logs/proof-report.json

.PHONY: all bootstrap test prove report clean distclean

all: report

bootstrap:
	@$(PYTHON) --version
	@$(PYTHON) -c 'import unittest'
	@printf '%s\n' 'bootstrap ok: standard-library Python harness is available'

test:
	PYTHONPATH=$(PYTHONPATH) $(PYTHON) -m unittest discover -s tests/verity -p 'test_*.py'

prove:
	@mkdir -p proofs/logs
	PYTHONPATH=$(PYTHONPATH) $(PYTHON) -m verity_srv3.prove > proofs/logs/prove.txt
	@cat proofs/logs/prove.txt
	PYTHONPATH=$(PYTHONPATH) $(PYTHON) -m verity_srv3.runner \
	  --targets verity/targets/srv3-proof-targets.json \
	  --fixtures tests/verity/fixtures \
	  --output $(PROOF_LOG)
	@printf '%s\n' 'proof report written to $(PROOF_LOG)'

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
