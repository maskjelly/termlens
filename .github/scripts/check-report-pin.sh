#!/usr/bin/env bash
# The `report` action is pinned by tag in three hand-maintained files, and
# the workspace version is a fourth copy of the same number. Three releases
# bumped two of the three and missed the action's own README (#386); this
# makes the pin checked rather than maintained, in the shape
# `check-candidate-statement.sh` already uses for the other promise made in
# more than one place.
#
# The three files are checked as a set rather than one by one: a listed file
# with no pin at all fails the same way a stale one does, so a copy that
# quietly disappeared is caught, and the file list is a single place to add
# the next one to.
#
# `REPORT_PIN_VERSION` overrides the workspace version, for the selftest
# only (`tools/report-pin-gate-selftest/`); CI never sets it.
#
# Usage: check-report-pin.sh [file ...]
#        (default: the three files that carry the pin)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

version="${REPORT_PIN_VERSION:-$(sed -n 's/^version *= *"\(.*\)"$/\1/p' "$root/Cargo.toml" | head -1)}"
if [ -z "$version" ]; then
  echo "::error::Cargo.toml has no workspace version"
  exit 1
fi

files=("$@")
if [ "${#files[@]}" -eq 0 ]; then
  files=(README.md .github/actions/report/README.md skills/termlens/SKILL.md)
fi

status=0
refs=0
for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "::error::\"$file\" is not a file"
    status=1
    continue
  fi
  found=0
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    found=$((found + 1))
    refs=$((refs + 1))
    if [ "$ref" != "report@v$version" ]; then
      echo "::error::$file pins \`$ref\` but the workspace version is $version"
      status=1
    fi
  done <<<"$(grep -oE 'actions/report@v[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?' "$file" \
    | sed 's|^actions/||' | sort -u || true)"
  if [ "$found" -eq 0 ]; then
    echo "::error::$file carries no \`actions/report@vX.Y.Z\` pin"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "report action pin: $refs ref(s) across ${#files[@]} file(s), every one at report@v$version"
fi
exit "$status"
