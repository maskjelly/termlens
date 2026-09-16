# Fixture: a file that lost its pin

A listed file carrying no `actions/report@vX.Y.Z` ref is drift too; without
this the gate would pass a file whose pin someone deleted.

- uses: vyncint/termlens/.github/actions/report
