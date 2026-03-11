# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Emacs configuration built over 15 years, targeting Emacs 30+ with native compilation. The entire config lives in two files: `early-init.el` and `init.el`.

## Architecture

### Bootstrap Order

1. **`early-init.el`** runs first: disables package.el, removes UI chrome (toolbar/scrollbar/menubar), sets fullscreen, bumps GC threshold and read-process-output-max for startup performance.
2. **`init.el`** runs second with this structure:
   - **Elpaca bootstrap** (lines 1–45): Package manager replacing package.el. Uses `elpaca-wait` sync points where later packages depend on earlier ones being fully installed.
   - **Org-mode** (lines 47–136): Loaded early because many packages depend on it. Agenda files, refile targets, custom agenda views (Kanban, Eisenhower matrix).
   - **Built-in packages** (lines 144–233): savehist, recentf, saveplace, autorevert, holidays (Berlin).
   - **Completion framework** (lines 235–357): Vertico + Orderless + Marginalia + Embark + Consult stack, plus consult-notes for org-roam.
   - **Helm** (lines 359–377): Deferred, only used for helm-bibtex.
   - **Org ecosystem** (lines 380–612): org-modern, org-roam (with dailies templates for journal/meetings/meditation/practice), citar, org-ref, org-roam-bibtex, org-roam-ui.
   - **Git** (lines 614–643): Magit + magit-delta + diff-hl.
   - **Dev tools** (lines 648–733): Flycheck (with LSP→ruff chaining workaround), tree-sitter, corfu, cape, envrc, apheleia (ruff formatter), combobulate.
   - **Python** (lines 744–800): LSP via lsp-pyright, dap-mode with debugpy, python-pytest, pet.
   - **Misc** (lines 802–948): super-save, tramp, which-key, helpful, midnight cleanup, grep (uses `git grep`).
   - **Theme/appearance** (lines 959–1009): Modus themes (vivendi/operandi-tinted toggle on F10), doom-modeline, ligatures, Iosevka font.

### Key Patterns

- **`elpaca-wait` sync points**: Used at line 233 (after diminish, before `:diminish` usage) and commented out at line 385 (before org-dependent packages). Adding/removing these affects load order.
- **Flycheck workaround** (lines 653–674): Local cache pattern to chain `lsp` → `python-ruff` checkers. The `my/flycheck-local-cache` variable + advice on `flycheck-checker-get` is a known workaround for flycheck#1762.
- **Custom functions** prefixed with `my/`: `my/create-scratch-buffer`, `my/ace-window`, `my/toggle-org-habit-today-only`, `my/org-agenda-wip-count`, `my/org-agenda-add-holidays`.
- **Platform conditionals**: `exec-path-from-shell` for macOS only; `toolbox-tramp` for Linux only; jinx snap workaround when `EMACS_SNAP_USER_COMMON` is set; `browse-url-chrome-incognito` dispatches differently on darwin vs linux (flatpak).

## Testing Changes

There is no test suite. To validate changes:
- `emacs --batch -l init.el` — check for load errors
- `emacs -Q -l early-init.el -l init.el` — test in clean session (note: elpaca bootstrap may re-download packages)

## Repository Rules

- **`.gitignore` uses an allowlist** — only explicitly listed files are tracked. Emacs generates many state files in this directory (history, recentf, org-roam.db, eshell/history, etc.) that contain personal data. When adding new files to the repo, they must be explicitly added to `.gitignore` with a `!` prefix.
- **`custom.el`** is intentionally excluded from git. It holds machine-local Custom settings via `custom-file`.
