#!/usr/bin/env bash
# Proves tools/preflight.sh accounts for every gate it runs, failures
# included (#368), before a green preflight is trusted:
#
#   failing/   one gate fails, one passes — both are asserted to be
#              reported, and the runner to exit non-zero
#   passing/   both pass — the runner is asserted to exit zero
#
# The fixtures are read through the runner's PREFLIGHT_DOC override, so the
# repository's own CONTRIBUTING.md is never touched.
#
# Usage: tools/preflight-selftest/run.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
root="$(cd ../.. && pwd)"
runner="$root/tools/preflight.sh"
status=0

# `<doc> <expected: zero|nonzero> <label> [grep pattern ...]`
# The patterns are what make "reports each gate" and "keeps going after a
# failure" assertions rather than exit-status coincidences.
expect() {
  doc=$1
  want=$2
  label=$3
  shift 3
  got=0
  PREFLIGHT_DOC="$PWD/$doc" "$runner" > out.log 2>&1 || got=$?
  case "$want:$got" in
    zero:0 | nonzero:[1-9]*) ;;
    *)
      printf '  FAIL  %-58s exit %s, expected %s\n' "$label" "$got" "$want" >&2
      sed 's/^/        /' out.log >&2
      status=1
      return
      ;;
  esac
  for pattern in "$@"; do
    if ! grep -Eq -- "$pattern" out.log; then
      printf '  FAIL  %-58s missing %s\n' "$label" "$pattern" >&2
      sed 's/^/        /' out.log >&2
      status=1
      return
    fi
  done
  printf '  ok    %-58s exit %s\n' "$label" "$got"
}

expect failing/CONTRIBUTING.md nonzero "a failing gate is reported and the run continues" \
  '^  FAIL  false' '^  ok    true'
expect passing/CONTRIBUTING.md zero "an all-passing fixture exits zero" \
  '^  ok    true'

rm -f out.log
if [ "$status" -eq 0 ]; then
  echo "preflight selftest: 2 expectation(s), the runner accounts for failures"
fi
exit "$status"
