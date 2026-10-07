#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

src="highlight.1.adoc"
out="highlight.1"

if command -v a2x >/dev/null 2>&1; then
	a2x -f manpage "$src"
elif command -v asciidoctor >/dev/null 2>&1; then
	asciidoctor -b manpage -o "$out" "$src"
else
	echo "error: need either a2x (asciidoc) or asciidoctor installed" >&2
	exit 1
fi

echo "built $out"
