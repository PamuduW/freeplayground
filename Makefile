.PHONY: hooks qa refresh-tree hadolint qa-full

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

refresh-tree:
	@if [ -x 10-automation-scripts/update-tree.sh ]; then \
		10-automation-scripts/update-tree.sh; \
	else \
		echo "Skipping tree refresh: 10-automation-scripts/update-tree.sh not found or not executable."; \
	fi

qa: $(PRE_COMMIT) refresh-tree
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files || true
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files

hado: $(PRE_COMMIT)
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files --hook-stage manual hadolint

qaf: qa hado
