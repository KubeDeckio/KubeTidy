# Logging and Output

KubeTidy supports verbose logging in both PowerShell and CLI usage.

## Examples

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose *>&1 | Tee-Object -FilePath "$HOME/kubetidy.log"
```

```bash
kubetidy --kubeconfig "$HOME/.kube/config" --verbose
kubectl kubetidy --kubeconfig "$HOME/.kube/config" --verbose
```

## Notes

- Verbose output includes reachability checks, backup creation, and merge processing.
- Cleanup and merge operations print a short summary after they complete.
- KubeTidy returns a non-zero exit code when a command fails, which makes it suitable for scripts and CI jobs.
