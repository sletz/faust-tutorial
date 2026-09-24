# The tutorial's checks and web site. `make help` lists the targets.
FAUST ?= faust
FAUSTPROBE ?= ../faust-rs/target/release/faustprobe
FAUSTLIBRARIES ?= ../../faustlibraries
DIR ?=
MKDOCS ?= python3 -m mkdocs

.DEFAULT_GOAL := help
.PHONY: help check docs site serve clean

help: ## Show the targets and the variables
	@printf "Usage:\n  make \033[36m<target>\033[0m [VARIABLE=value ...]\n\nTargets:\n"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf "\nVariables (current value):\n"
	@printf "  %-15s %s\n" FAUST "$(FAUST)" FAUSTPROBE "$(FAUSTPROBE)" FAUSTLIBRARIES "$(FAUSTLIBRARIES)" \
		DIR "$(DIR) (check: one folder or file, e.g. DIR=examples/07; empty: all)" MKDOCS "$(MKDOCS)"

check: ## Check every program: C++ faust, faustprobe, the checks in its comments (DIR= to restrict)
	FAUST=$(FAUST) FAUSTPROBE=$(FAUSTPROBE) FAUSTLIBRARIES=$(FAUSTLIBRARIES) python3 scripts/check.py $(DIR)

docs: ## Prepare the site's sources in build/docs: diagrams (faust -svg) and editors
	FAUST=$(FAUST) FAUSTLIBRARIES=$(FAUSTLIBRARIES) python3 scripts/build_docs.py

site: docs ## Build the web site in site/ (mkdocs, strict)
	$(MKDOCS) build --strict

serve: docs ## Serve the web site at http://127.0.0.1:8000 while editing
	$(MKDOCS) serve

clean: ## Remove build/ and site/
	rm -rf build site
