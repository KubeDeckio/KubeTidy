# KubeTidy Usage

This section walks through the most common ways to use **KubeTidy** day to day, whether you're working in PowerShell or through `kubectl`.

- [PowerShell Usage](powershell-usage.md) for `Invoke-KubeTidy`
- [Krew Plugin Usage](krew-usage.md) for `kubectl kubetidy`

## Main workflows

- list clusters and contexts in a kubeconfig
- remove unreachable clusters
- keep selected clusters excluded from cleanup
- export selected contexts to a filtered kubeconfig
- merge multiple kubeconfig files
- preview changes with dry-run mode
- inspect a kubeconfig with `report` mode
- emit structured `json` or `yaml` output for automation

For a full list of commands, flags, output modes, and merge behavior, see the [CLI Reference](../reference/commands.md).
