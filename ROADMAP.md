# KubeTidy Go Migration Roadmap

## Goals

- Preserve the current PowerShell entrypoint: `Invoke-KubeTidy`
- Preserve the current kubectl/Krew command flags
- Stop corrupting kubeconfig files by using typed read/write paths
- Move business logic into a native Go binary so KubeTidy is easier to distribute beyond PowerShell users

## Current command parity target

- `--kubeconfig`
- `--exclusionlist`
- `--backup`
- `--force`
- `--listclusters`
- `--listcontexts`
- `--exportcontexts`
- `--mergeconfigs`
- `--destinationconfig`
- `--dryrun`
- `--ui`
- `--verbose`

## Migration phases

1. Stabilize kubeconfig mutation.
   Replace manual YAML string building with typed kubeconfig loading and writing so cleanup, merge, and export preserve all existing cluster, user, context, and auth fields.

2. Introduce the Go CLI.
   Add `cmd/kubetidy` and move kubeconfig operations into `internal/kubeconfig` while keeping the current flat flag model for compatibility with existing docs and Krew usage.

3. Keep the PowerShell wrapper.
   Make `Invoke-KubeTidy` a thin forwarding layer so PowerShell users keep the same command and parameter names while the implementation lives in Go.

4. Add regression coverage.
   Create fixture-based tests for cleanup, merge, and export, especially for exec auth, token auth, named extensions, and current-context handling.

5. Update packaging.
   Publish native binaries for supported OS/arch targets, update Krew packaging to remove the PowerShell runtime requirement, and ship the PowerShell module with the wrapper plus embedded binaries.

## Known follow-up work

- Add automated tests around kubeconfig round-tripping
- Update release automation for multi-platform Go builds
- Refresh docs and examples to describe both native CLI and PowerShell wrapper usage
- Re-evaluate a TUI after report/output/subcommand workflows settle; a weak review UI is not worth shipping
