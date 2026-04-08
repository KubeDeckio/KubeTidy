# PowerShell Usage

If you're using **KubeTidy** with PowerShell, this guide shows how to clean up, inspect, and manage your `kubeconfig` files with `Invoke-KubeTidy`.

## Common commands

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListClusters
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListContexts
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Report -Output json
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExportContexts "context1,context2" -DestinationConfig "$HOME\.kube\filtered-config"
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config" -MergeStrategy keep-first
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -DryRun -Force
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose
```

## Notes

- A backup is created automatically before writes unless `-DryRun` is used.
- `Invoke-KubeTidy` works well in scripts, terminals, and existing PowerShell automation.
- Use `-ProbeTimeoutSeconds` if a slow cluster endpoint needs a longer reachability probe during cleanup.
- Use `-Output json` or `-Output yaml` when you want structured results for automation.
- Use `-Report` to inspect a kubeconfig without modifying it.
- Use `-Doctor` to highlight kubeconfig issues such as orphaned contexts, unused users, or duplicate servers.
