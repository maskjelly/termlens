#!/usr/bin/env bash
# Every gate CI runs must appear in CONTRIBUTING.md §1's "run these before
# pushing" block. The paragraph under that block promises the workflow is
# the source of truth when the two disagree; this is what makes the promise
# hold. Usage: check-ci-gates-listed.sh [ci.yml] [CONTRIBUTING.md]
set -euo pipefail

ci="${1:-.github/workflows/ci.yml}"
doc="${2:-CONTRIBUTING.md}"

# Single-line reproducible gates start with `cargo`, `.github/scripts/` or
# `tools/`. Multi-line `run: |` blocks are job plumbing (the msrv assertion,
# the zizmor retry, required-green's jq) and are not something a contributor
# types.
ci_cmds="$(sed -n -E 's/^[[:space:]]*- run: (cargo |\.github\/scripts\/|tools\/)(.*)$/\1\2/p' "$ci" | sed -E 's/[[:space:]]+/ /g')"
cargo_count="$(grep -c '^cargo ' <<<"$ci_cmds" || true)"
script_count="$(grep -Ec '^(\.github/scripts/|tools/)' <<<"$ci_cmds" || true)"

# CONTRIBUTING §1: the shared extraction in extract-gates.sh (#368), plus
# the normalisations this comparison alone needs — the RUSTDOCFLAGS prefix
# and a `+toolchain` selector removed, because `cargo +1.85 check` in the
# doc is `cargo check` under RUSTUP_TOOLCHAIN in the workflow.
doc_cmds="$("$(dirname "${BASH_SOURCE[0]}")/extract-gates.sh" "$doc" \
  | sed -E -e "s/^RUSTDOCFLAGS='-D warnings' //" \
           -e 's/^cargo \+[^ ]+ /cargo /')"

status=0
while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  if ! grep -Fxq -- "$cmd" <<<"$doc_cmds"; then
    echo "::error::CI runs \`$cmd\` but CONTRIBUTING.md §1 does not list it"
    status=1
  fi
done <<<"$ci_cmds"

# zizmor is pinned in the workflow; the doc must name the same pin.
pin="$(grep -o 'zizmor==[0-9.]*' "$ci" | head -1)"
if [ -n "$pin" ] && ! grep -Fq -- "$pin" "$doc"; then
  echo "::error::CI pins \`$pin\` but CONTRIBUTING.md names a different zizmor, or none"
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "every CI gate is listed in CONTRIBUTING.md §1 ($cargo_count cargo commands, $script_count script gates, $pin)"
fi
exit "$status"
