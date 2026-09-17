#!/usr/bin/env bash
# Proves the report-action pin gate can fail, before it is trusted to pass
# (#386).
#
# Four fixtures model the ways the pin drifts: a matching ref, a stale one,
# a listed file that lost its ref entirely, and a file with two refs where
# only one was bumped. They are written against an injected version so they
# do not go stale with the workspace every release; the last assertion drops
# the injection and runs the repository's own three files against the real
# workspace version, which is what a green CI run means.
#
# Usage: tools/report-pin-gate-selftest/run.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
root="$(cd ../.. && pwd)"
gate="$root/.github/scripts/check-report-pin.sh"
status=0

# `<version|-> <expected: zero|nonzero> <label> <file ...>`
# `-` runs the gate without the injection, against the real workspace.
expect() {
  version=$1
  want=$2
  label=$3
  shift 3
  got=0
  if [ "$version" = "-" ]; then
    "$gate" "$@" > out.log 2>&1 || got=$?
  else
    REPORT_PIN_VERSION="$version" "$gate" "$@" > out.log 2>&1 || got=$?
  fi
  case "$want:$got" in
    zero:0 | nonzero:[1-9]*)
      printf '  ok    %-58s exit %s\n' "$label" "$got" ;;
    *)
      printf '  FAIL  %-58s exit %s, expected %s\n' "$label" "$got" "$want" >&2
      sed 's/^/        /' out.log >&2
      status=1 ;;
  esac
}

expect 9.9.9 zero "a matching pin passes" matching.md
expect 9.9.9 nonzero "a stale pin fails" stale.md
expect 9.9.9 nonzero "a listed file with no pin fails" absent.md
expect 9.9.9 nonzero "one stale ref among two fails" twice.md
expect - zero "this repository's own three files pass" "$root/README.md" \
  "$root/.github/actions/report/README.md" "$root/skills/termlens/SKILL.md"

rm -f out.log
if [ "$status" -eq 0 ]; then
  echo "report-pin gate selftest: 5 expectation(s), the gate fails when it should"
fi
exit "$status"
