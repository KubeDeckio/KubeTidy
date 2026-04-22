# CLI Reference

This page covers the `kubetidy` command-line interface.

## Core flags

| Flag | Purpose |
| --- | --- |
| `--kubeconfig` | Path to the kubeconfig file to inspect or clean. |
| `--exclusionlist` | Comma-separated cluster names to skip during cleanup. |
| `--backup` | Create a backup before cleanup. Enabled by default. |
| `--force` | Allow cleanup to continue even if no clusters are reachable. |
| `--listclusters` | Print cluster names and stop. |
| `--listcontexts` | Print context names and stop. |
| `--report` | Show a kubeconfig report without modifying any files. |
| `--doctor` | Run kubeconfig health checks and surface risky entries without modifying any files. |
| `--exportcontexts` | Export only the named contexts into another kubeconfig. |
| `--mergeconfigs` | Add a kubeconfig file to the merge set. Repeat the flag for multiple files. |
| `--destinationconfig` | Output path for merge or export. |
| `--dryrun` | Show what would happen without writing changes. |
| `--probe-timeout-seconds` | Timeout for cluster reachability probes during cleanup. Default: `5`. |
| `--output` | Output format: `text`, `json`, or `yaml`. |
| `--merge-strategy` | Duplicate-name handling: `keep-first`, `keep-last`, or `fail-on-conflict`. |
| `--ui` | Suppress the banner when you do not want terminal decoration. |
| `--verbose` | Print detailed progress and duplicate-skip messages. |
| `--version` | Print the CLI version. |

## Common examples

### List clusters

```bash
kubetidy --kubeconfig "$HOME/.kube/config" --listclusters
```

### Clean unreachable clusters with a longer probe timeout

```bash
kubetidy --kubeconfig "$HOME/.kube/config" --force --probe-timeout-seconds 8
```

### Report on a kubeconfig in JSON

```bash
kubetidy --kubeconfig "$HOME/.kube/config" --report --output json
```

### Run doctor checks

```bash
kubetidy doctor --kubeconfig "$HOME/.kube/config" --output yaml
```

### Preview cleanup first

```bash
kubetidy --kubeconfig "$HOME/.kube/config" --dryrun --force
```

### Export selected contexts

```bash
kubetidy --kubeconfig "$HOME/.kube/config" \
  --exportcontexts "prod-a,prod-b" \
  --destinationconfig "$HOME/.kube/filtered-config"
```

### Merge multiple kubeconfig files

```bash
kubetidy \
  --mergeconfigs config1.yaml \
  --mergeconfigs config2.yaml \
  --destinationconfig "$HOME/.kube/config"
```

### Generate completions

```bash
kubetidy completion powershell
kubetidy completion zsh
```

### Show build metadata

```bash
kubetidy version
kubetidy --version
```

## Doctor checks

`doctor` builds on `report` and highlights the entries that are most likely to cause real problems:

- missing current context
- orphaned contexts
- unused users
- duplicate cluster server endpoints
- duplicate names encountered while merging multiple source files

## Merge behavior

KubeTidy currently uses a **keep-first** merge strategy for duplicate names:

- the first cluster with a given name wins
- the first context with a given name wins
- the first user with a given name wins

Later duplicates are skipped. Duplicate counts are shown in the merge summary, and `--verbose` logs which names were skipped.

## Multi-file KUBECONFIG

If `KUBECONFIG` contains multiple files, KubeTidy loads them as a merged view using the selected merge strategy.

- `keep-first` keeps the first named cluster, context, or user it sees
- `keep-last` lets later files override earlier ones
- `fail-on-conflict` stops if duplicate names differ
