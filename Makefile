.PHONY: hooks qa

PYTHON ?= python3
VENV ?= .venv
PRE_COMMIT ?= $(VENV)/bin/pre-commit
PRE_COMMIT_HOME ?= $(CURDIR)/.cache/pre-commit

$(PRE_COMMIT):
	$(PYTHON) -m venv $(VENV)
	$(VENV)/bin/python -m pip install pre-commit

hooks: $(PRE_COMMIT)
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) install --install-hooks --hook-type pre-commit

qa: $(PRE_COMMIT)
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files || true
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files
