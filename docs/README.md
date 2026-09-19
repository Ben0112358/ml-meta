# ml-meta documentation

Read this index before changing ml-meta or any pipeline repository.

| Document | Purpose |
|----------|---------|
| [architecture.md](architecture.md) | Stage chain, environment contract, coupling, dev vs prod |
| [repositories.md](repositories.md) | Where each repo lives, remotes, lint and test commands |
| [conventions.md](conventions.md) | Layout, naming, formatting, tooling |
| [workflows.md](workflows.md) | Git and cross-repo development loop |
| [new-project.md](new-project.md) | Checklist for adding a project across stages |

Local layout assumes all repositories are siblings under `$ML_HOMELAB_ROOT`. Scripts in [`../scripts/`](../scripts/) derive that root automatically when the env var is unset.
