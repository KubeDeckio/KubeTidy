# KubeTidy Documentation

KubeTidy is a kubeconfig management tool for Kubernetes users who need to clean up stale clusters, merge configs, and safely export just the contexts they care about.

You can use it in three ways:

- `kubetidy`
- `kubectl kubetidy`
- `Invoke-KubeTidy`

## Why teams use KubeTidy

- It removes unreachable clusters and the users and contexts tied to them
- It creates backups before writing unless you run in dry-run mode
- It preserves supported kubeconfig fields instead of rewriting partial configs
- It can merge multiple kubeconfig files without losing remaining entries
- It can export selected contexts into a smaller focused kubeconfig
- It can inspect kubeconfig health with `report` and `doctor`

## Read next

- [Installation](installation.md)
- [Usage](usage/index.md)
- [Logging and Output](usage/logging-output.md)
- [Contributing](contributing.md)
