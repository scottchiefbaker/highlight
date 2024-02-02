# Highlight

Written by Dave Goodell <davidjgoodell@gmail.com>

Forked and modified by Scott Baker <scott.baker@gmail.com>

---

### Usage:

```
highlight <PATTERN0> [PATTERN1...]

highlight [--filter COLOR,PATTERN] [--filter COLOR,PATTERN] ...
```

This program takes text via STDIN and outputs it with the given
[patterns](https://perldoc.perl.org/perlre.html) highlighted with various colors.
If no color option is specified, it defaults to a pre-selected array of colors.

If you filter contains capturing parens, *only* the captured text will be
highlighted. If this is not the behavior you want you can use non-capturing
parens, or use the `--full_matches` param.

Passing `--case_sensitive` will enable case-sensitive matching. Otherwise
case-insentive matching is used, unless there is a capital letter in your filter,
in which case case-senstive is used (Vim smartcase).

If your pattern begins with a dash, you can pass a `--` argument
after any options and before your pattern to distinguish it from an
option.

### Params:

| Option               | Description                                              |
| -------------------- | -------------------------------------------------------- |
| `--case_insensitive` | pattern matching is **not** case sensitive (default)     |
| `--case_sensitive`   | pattern matching is case sensitive                       |
| `--filter`           | a color and pattern pair (separated by a comma)          |
| `--force`            | force coloring on, even when not connected to a terminal |
| `--full_matches`     | colorize entire match, not just captured parens          |
| `--file`             | read patterns from a file                                |
| `--help`             | show command usage                                       |

**Note:** Patterns read from a file are one per line. If patterns tab are separated,
they use advanced `--filter COLOR,PATTERN` style syntax. Where the COLOR is the
first column, one or more tabs, and then PATTERN.

### Notes:
Highlight requires a 256 color capable terminal. If you're still running a 16
color terminal this will probably look pretty ugly.

This package also includes a bonus script `bleach_text` to strip out
ANSI color escape sequences.

### Colors:

Filters can be assigned a **specific** color by using the ANSI number available in the `term-colors.pl` script.

### Examples:
```
cat README.md | highlight colors? by 'pattern[\ds]?' text program with '\bhighlight\b'

cat nagios.log | highlight --filter '11,\bWARNING\b' --filter '82,\bOK\b' --filter '196,\bCRITICAL\b'

cat messages.log | highlight --file /tmp/patterns.txt
```
