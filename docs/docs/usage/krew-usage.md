# Krew Plugin Usage

The Krew package installs a native binary that runs as `kubectl kubetidy`.

## Common commands

```bash
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --listclusters
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --listcontexts
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --report --output yaml
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --exportcontexts "context1,context2" --destinationconfig "$HOME/.kube/filtered-config"
kubectl kubetidy --mergeconfigs config1.yaml --mergeconfigs config2.yaml --destinationconfig "$HOME/.kube/config" --merge-strategy keep-first
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --dryrun --force
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --verbose
```

## Notes

- Krew uses GNU-style `--flags`.
- The plugin creates a timestamped backup before writing unless `--dryrun` is used.
- If the current context belongs to a removed cluster, KubeTidy clears it.
- Duplicate names during merge use keep-first behavior. Later duplicates are skipped and counted in the summary.
- Use `--output json` or `--output yaml` for scripting and CI.
