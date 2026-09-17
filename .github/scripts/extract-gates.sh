#!/usr/bin/env bash
# extract-gates.sh — print CONTRIBUTING §1's documented commands, one per
# line: every ```sh fence between "## 1." and "## 2." (the clone-and-enter
# setup, the gate block and the snapshot-review notes), comments stripped,
# whitespace collapsed. The RUSTDOCFLAGS prefix and a `+toolchain` selector
# are left as written, so tools/preflight.sh can run the line verbatim.
#
# Two callers, deliberately (#368): check-ci-gates-listed.sh compares the
# result against ci.yml's cargo steps, and tools/preflight.sh runs the
# subset of it that is a gate. Neither keeps its own copy of the list.
#
# Extended regex throughout: BSD sed has no \+ in basic.
# Usage: extract-gates.sh [doc]   (default CONTRIBUTING.md)
set -euo pipefail

doc="${1:-CONTRIBUTING.md}"

awk '/^## 1\./{s=1} /^## 2\./{s=0} s' "$doc" \
  | awk '/^```/{f=!f; next} f' \
  | sed -E -e 's/#.*$//' \
           -e 's/[[:space:]]+/ /g' -e 's/^ //' -e 's/ $//' \
  | grep -v '^$'
