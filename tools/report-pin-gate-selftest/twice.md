# Fixture: two refs, one bumped

The bumped half matches and the other does not; the gate must fail on the
stale one rather than the file passing because a ref was found at all.

- uses: vyncint/termlens/.github/actions/report@v9.9.9
- uses: vyncint/termlens/.github/actions/report@v9.9.8
