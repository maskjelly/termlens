# Fixture: the #384 shape — a link that resolves from the repository root

`docs/LIMITATIONS.md` linked its siblings as `docs/DESIGN.md`, which is right
from the root and `docs/docs/DESIGN.md` from the file. Every link below has
that shape: present at the repository root, absent where this file sits.

- [the agent brief](AGENTS.md)
- [releasing](docs/RELEASING.md)
- [the workflow](.github/workflows/ci.yml)
