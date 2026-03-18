.PHONY: hooks qa refresh-tree hadolint qa-full hado qaf tag-week tgw tag-status

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

hadolint: $(PRE_COMMIT)
	mkdir -p $(PRE_COMMIT_HOME)
	PRE_COMMIT_HOME=$(PRE_COMMIT_HOME) $(PRE_COMMIT) run --all-files --hook-stage manual hadolint

qa-full: qa hadolint

WEEK ?= $(w)

tag-week:
ifeq ($(WEEK),)
	$(error Usage: make tag-week WEEK=NN  (or: make tgw W=NN))
endif
	@10-automation-scripts/tag-week.sh $(WEEK)

tag-status:
	@latest=$$(git tag -l 'week-*' | sort -V | tail -1); \
	if [ -z "$$latest" ]; then \
		echo "No week tags yet."; \
	else \
		echo "Latest tag: $$latest ($$(git log -1 --format='%h %s' $$latest))"; \
	fi
	@branch=$$(git rev-parse --abbrev-ref HEAD); \
	echo "Branch:     $$branch"

# Backward-compatible aliases.
hado: hadolint
qaf: qa-full
tgw: tag-week
tgs: tag-status
