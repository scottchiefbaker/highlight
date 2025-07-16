# 🎨 Highlight

Highlight and colorize text patterns in your terminal for easier readability.

---

### ✨ Usage:

```
highlight <PATTERN0> [PATTERN1...]

highlight [--filter COLOR,PATTERN] [--filter COLOR,PATTERN] ...
```

This program takes text via STDIN and outputs it with the given
[regex](https://perldoc.perl.org/perlre.html) patterns highlighted in color.
If no specific color option is provided, highlight will default to a
pre-selected array of colors.

**Example:** `cat logfile.txt | highlight --filter 'green,pass' --filter 'red,fail'`

If your filter contains capturing parens, *only* the captured text will be
highlighted. If this is not the behavior you want you can use non-capturing
parens, or use the `--full_matches` param.

Highlight uses Vim style smartcase matching. If your filter contains a capital
letter then matches are case-**sensitive**, otherwise they are case-insensitive.
Options for `--case_sensitive` and `--case_insensitive` are available as overrides.

If your match pattern begins with a dash, you will have to use the `--filter` syntax
so highlight can differentiate between a filter and a param.

**Example:** `cat README.md | highlight --filter 'green,--'`

### 🔡 Params:

| Option                   | Description                                              |
| ------------------------ | -------------------------------------------------------- |
| `--bold`                 | output matched patterns using bold font                  |
| `--case_insensitive` `-i`| pattern matching is **not** case sensitive (default)     |
| `--case_sensitive`       | pattern matching is case sensitive                       |
| `--file`                 | read patterns from a file                                |
| `--filter` `-f`          | a color and pattern pair (separated by a comma)          |
| `--force`                | force coloring on, even when not connected to a terminal |
| `--full_matches`         | colorize entire match, not just captured parens          |
| `--help`                 | show command usage                                       |

**Note:** Patterns read from a file are one per line. If lines are tab separated,
they use advanced `--filter COLOR,PATTERN` style syntax. Where the COLOR is the
first column, one or more tabs, and then PATTERN.

### 🖼️ Screenshot:

<img width="1058" height="772" alt="Highlight screenshot" src="https://github.com/user-attachments/assets/4c169c5a-0dd2-4e74-8de3-0484d1f68a9b" />

### 🗒️ Notes:
Highlight requires a 256 color capable terminal. If you're still running a 16
color terminal this will probably look pretty ugly.

### 🌈 Colors:

Filters use the color of the ANSI numbers available in the `term-colors.pl`
script in the `extras/` directory. Alternately some colors can be defined as a
string shortcut: red, blue, green, yellow, orange, purple, white, and black.

### 🧪 Examples:
```
cat README.md | highlight colors? by 'pattern[\ds]?' filter case with '\bhighlight\b'

cat nagios.log | highlight --filter '11,\bWARNING\b' --filter '82,\bOK\b' --filter '196,\bCRITICAL\b'

cat messages.log | highlight --file /tmp/patterns.txt
```

### 👨 Team

| Username         | Role            |
| ---------------- | --------------- |
| @scottchiefbaker | Lead programmer |
| @goodell         | Original author |
