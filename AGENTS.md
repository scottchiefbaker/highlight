# highlight — agent guide

Single-file Perl CLI tool (`highlight`) that reads STDIN and colorizes regex matches using ANSI 256-color escape sequences.

## Quick commands

| Action | Command |
|--------|---------|
| Run all tests | `perl t/01-highlight.t` |
| Run tests with debug | `perl t/01-highlight.t --debug` |
| Test a specific pattern | `echo "foo bar" | perl highlight --force foo` |

## Repo structure

- **`highlight`** — the only source file (435 lines). Entrypoint, all logic, and CLI arg parsing in one Perl script. Version `v1.8.5` (line 19).
- **`t/01-highlight.t`** — `Test::More` test file with inline helpers that convert ANSI escapes to `[COLORNNN]` / `[BOLD]` / `[RESET]` / `[BACKGNNN]` tokens for comparison.
- **`extras/`** — utility scripts: `term-colors.pl` (display 256-color table), `bleach_text` (strip ANSI codes).
- **`docs/`** — empty directory.
- No build system, no package manifest, no CI config, no linter/formatter config.

## Key facts

- **No dependencies.** Uses only core Perl modules (v5.16+). `Getopt::Long` for CLI. Optional: `Data::Dump::Color` (for debug `k()`/`kd()`), `Term::ANSIColor` (for `term-colors.pl --perl`).
- **No build step.** Runs directly: `perl highlight PATTERN`.
- **Testing quirks:** Always use `--force` (disables terminal detection). Test compares against bleached ANSI tokens. Use `--debug` to echo the piped command. Default color cycle: `(33,11,9,47,214,99,15,51,198,94)` — wraps after 10 patterns.
- **Smartcase matching:** Default. Uppercase letter in pattern → case-sensitive; all-lowercase → case-insensitive. Override with `--case_sensitive`/`-s` or `--case_insensitive`/`-i`.
- **Capturing parens:** If pattern has `(...)`, only captured groups are highlighted. Use `--full_matches` to highlight the entire match.
- **Patterns starting with `-`:** Must use `--filter COLOR,PATTERN` to avoid flag ambiguity.
- **Env vars:** `HIGHLIGHT_COLORS` (comma-separated ANSI numbers, overrides default color cycle). `NO_COLOR` disables color output (overridden by `--force`).
- **`--file`:** Reads patterns from a file. Plain lines = bare patterns. Tab-separated = `COLOR\tPATTERN`. Lines starting with `#` are comments.
- **Color shortcuts:** `red` (160), `blue` (27), `green` (34), `yellow` (226), `orange` (214), `purple` (93), `white` (15), `black` (0). ANSI 256 numbers work directly. Suffixes: `_bold` (e.g., `165_bold`), `on_COLOR` (background, e.g., `10_on_140`, `white_on_blue`). True color hex `#RRGGBB` supported.
- Requires a 256-color terminal. `--force` enables output in pipelines/tests.
