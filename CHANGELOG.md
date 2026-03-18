# Changelog
All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows SemVer where releases are used.

## [Unreleased]
### Added
- Week 03: Docker Compose demo (FastAPI + Redis), healthchecks, restart policies, Compose debugging guide (`02-docker/info/docker-compose.md`)
- Week 03: weekly tagging automation (`make tag-week` / `make tgw`), pre-commit tag check hook, `tag-week.sh` and `check_prev_week_tag.sh` scripts
- Week 03: moved `live-project-idea.md` to `docs/info/` and added "Live project add-on" section to the game plan
- Week 02 Add-on 01: linting and formatting workflow (`pre-commit`, `markdownlint`, `prettier`, `yamllint`, `ruff`, `shfmt`, `shellcheck`), Makefile quality targets, `.gitlab-ci.yml` verify stage
- Week 02: Docker fundamentals module (`02-docker/`), single-stage and multistage Dockerfiles, FastAPI demo app, volume and network docs
- Week 01: initialized repo, folder skeleton, and CI scaffold
- GitLab pipeline badge and mirroring to GitHub
- Weekly notes structure and evidence screenshots

### Changed
- Week 03: renamed `FreePlayground_Game_Plan_v3.md` to `FreePlayground_Game_Plan.md`; updated all references
- Week 03: tagging is now a required end-of-week step (no longer optional); week branches are kept after merge
- Week 03: updated FastAPI app to use Redis for visit counting; `/health` endpoint now reports Redis connectivity
- Week 02 Add-on 01: added `Makefile`, `.pre-commit-config.yaml`, `.yamllint`, `.markdownlint-cli2.yaml`, `.prettierignore`, `pyproject.toml`
- Renamed default branch from master to main

### Fixed
- N/A

## [0.1.0]
### Added
- Initial public lab notebook structure
