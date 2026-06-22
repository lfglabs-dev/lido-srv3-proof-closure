MAIN      := report
LATEXMK   := latexmk
ENGINE    := -pdf
FLAGS     := -interaction=nonstopmode -halt-on-error -file-line-error
OUT_DIR   := build
DIST_DIR  := dist

.PHONY: all clean distclean

all: $(DIST_DIR)/lido-srv3-formal-methods-report.pdf

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
