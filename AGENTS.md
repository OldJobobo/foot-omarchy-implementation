# Repository Guidelines

## Project Structure & Module Organization
This repository packages Omarchy + Foot setup docs and deployable dotfiles.

- `docs/omarchy-foot-setup.md`: canonical setup and operational instructions.
- `implementation/.config/...`: config files mirrored to user config paths (Foot, Omarchy hooks, terminal preference).
- `implementation/.local/bin/omarchy-launch-screensaver`: launcher script override.
- `README.md`: inventory of copied files and original source locations.

When adding files, mirror real target locations under `implementation/` (for example, `implementation/.config/<app>/...`).

## Build, Test, and Development Commands
There is no compile/build step. Use validation commands before opening a PR:

- `bash -n implementation/.local/bin/omarchy-launch-screensaver` checks shell syntax.
- `bash -n implementation/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh` validates the hook script.
- `rg "TODO|FIXME" docs implementation` surfaces unfinished edits.
- `git diff -- docs implementation` reviews only deliverable content.

If testing on a live Omarchy system, verify runtime behavior with:
- `xdg-terminal-exec --print-id`
- `omarchy-theme-set "$(omarchy-theme-current)"`

## Coding Style & Naming Conventions
- Shell scripts: POSIX/Bash-safe style, 2-4 space indentation, quote variables, prefer explicit command checks (`command -v ...`).
- Config/templates: keep key order stable; avoid reformatting unrelated lines.
- File naming: keep hook numbering prefix (`NN-description.sh`) in `theme-set.d/` (example: `26-foot-live-colors.sh`).
- Documentation: short imperative steps, fenced blocks for commands, and expected output where relevant.

## Testing Guidelines
No formal test framework is configured. Treat syntax checks + manual smoke tests as required:

- Run `bash -n` for every changed `.sh` file.
- Re-run critical flows from `docs/omarchy-foot-setup.md` after changes.
- For docs-only edits, verify commands and paths match files in `implementation/`.

## Commit & Pull Request Guidelines
Current history is minimal (`initial commit`), so follow a clear, consistent format:

- Commit messages: short imperative subject, optional scope (example: `docs: clarify footclient verification step`).
- PRs should include: purpose, changed paths, manual validation performed, and before/after behavior notes.
- Include terminal output snippets or screenshots when behavior or UX changes.
