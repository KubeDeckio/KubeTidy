# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.21] - 2024-12-06

### Fixed
- **Fixed ASCII Art Banner**: The ASCII art banner has been reintroduced to the KubeTidy output after adjustments to ensure it displays correctly in the updated KubeDeck UI. This change improves compatibility and enhances the visual clarity of the output for users.

### [0.0.20] - 2024-10=28

#### Added
- Verbose-only output for script execution in both local and Krew storage directories.

#### Changed
- Modified script to check both local and Krew storage paths for `.ps1` files, ensuring failover functionality.
- Introduced a `$foundScripts` flag to track sourcing success across directories.

#### Fixed
- Improved error handling to terminate execution with an error if no `.ps1` files can be sourced from either path.

#### Notes
- Script now exits with an error message if both local and Krew storage directories lack the required `.ps1` files.

## [0.0.19] - 2024-10-28

### Changed
- **Re-added ASCII Art Banner**: The ASCII art banner has been reintroduced to the KubeTidy output after adjustments to ensure it displays correctly in the updated KubeDeck UI. This change improves compatibility and enhances the visual clarity of the output for users.

### Fixed
- **MacOS ARM Compatibility in Krew**: Updated the loading process for PowerShell modules to restore support for macOS ARM systems, similar to the compatibility achieved in version 0.0.14.

## [0.0.18] - 2024-10-22

### Changed
- **Removed ASCII Art Banner**: The ASCII art banner was removed from the KubeTidy output as it was not displaying correctly in the new KubeDeck UI. This change improves compatibility with the user interface and enhances the overall visual clarity of the output.

## [0.0.17] - 2024-10-17

### Added
- **Darwin ARM64 and Linux ARM64 Support**: Added support for Darwin ARM64 and Linux ARM64 platforms, including building and packaging the respective binaries.
- **Automatic Update of `KubeTidy.yaml`**: The GitHub Actions workflow now automatically updates the `KubeTidy.yaml` file during the release process. It replaces placeholders with the correct version, URLs, and SHA256 checksums for each platform (Linux/AMD64, Linux/ARM64, Darwin/AMD64, and Darwin/ARM64).
- **Upload `KubeTidy.yaml` to GitHub Release**: The updated `KubeTidy.yaml` file is now uploaded to the release as an asset, along with the platform-specific tar.gz files and SHA256 checksums.

### Changed
- **Backup Function Return Status**: Updated the `New-Backup` function to return a success or failure status via the `-PassThru` parameter. The backup process now supports better error handling, allowing the script to abort the cleanup if the backup fails.

### Fixed
- **Cleanup Without ExclusionList**: Fixed an issue where the cleanup would only run if the `ExclusionList` parameter was provided. The script now defaults the `ExclusionList` to an empty array, allowing cleanup to proceed even when the parameter is not specified.

### Improved
- **Error Handling for Backups**: Enhanced error handling during the backup process using `try/catch` blocks. If the backup fails, the script stops the cleanup process to prevent data loss.


## [0.0.16] - 2024-10-07

### Fixed
- **PowerShell Module Submodule Import**: Fixed an issue where submodules were not being correctly imported within the PowerShell module, ensuring smoother module usage and proper functioning of submodule dependencies. Krew module still needs some work.

## [0.0.15] - 2024-10-02

### Added
- **List Contexts Option**: Added the `-ListContexts` parameter, allowing users to list all available contexts in the kubeconfig.
- **Export Contexts Option**: Introduced the `-ExportContexts` parameter for exporting specific contexts from the kubeconfig. This can be combined with the `-DestinationConfig` parameter to specify the output path.
- **Preserve Current Context**: Added logic to preserve the current context in the cleaned kubeconfig unless it belongs to a removed cluster.

### Changed
- **Reusable DestinationConfig**: The `-DestinationConfig` parameter is now shared between the merge and export functionalities, simplifying the user experience.

### Fixed
- **Current Context Handling**: Fixed an issue where the current context could be removed inadvertently during cleanup. The script now retains the current context unless its associated cluster is removed.

## [0.0.14] - 2024-10-01

### Added
- **Krew Support**: Added support for Krew, allowing users to install and manage KubeTidy as a plugin in their Kubernetes environment.
- **Release Notes Automation**: Integrated automation to update GitHub release notes with entries from the CHANGELOG.md based on the version being released.

### Changed
- **Refactor Release Process**: Improved the release workflow by adding automated steps for generating tar files and checksums, ensuring a smoother release experience.

### Fixed
- **Restored Backup feature** Whilst splitting out files, Backup parameter went missing. Added back now.
- Minor bug fixes and improvements to enhance performance and stability.

## [0.0.13] - 2024-10-01

### Fixed
- **Importing sub modules error**: Fixed an issue where the sub modules were not being imported.

## [0.0.12] - 2024-10-01

### Added
- **Dry Run Mode:** Introduced the `-DryRun` parameter, allowing users to simulate cleanup and merging processes without making any changes. This provides a preview of actions KubeTidy would perform.

## [0.0.11] - 2024-09-30

### Added
- **Merge Kubeconfig Files:** Introduced the ability to merge multiple kubeconfig files into one using the `-MergeConfigs` parameter. Users can specify multiple kubeconfig file paths to be merged into the destination kubeconfig file.
- **DestinationConfig Parameter:** Added the `-DestinationConfig` parameter for specifying the output path of the merged kubeconfig file. If not specified, it defaults to `"$HOME/.kube/config"`.
- **Cluster Count Output:** The `-ListClusters` parameter now also outputs the total number of clusters present in the kubeconfig file after listing them.

## [0.0.10] - 2024-09-27

### Added
- **Clickable Backup Path**: Backup path is now clickable if the terminal supports it, making it easier to navigate to backup files.
- **Manual YAML Handling for Single Entries**: Ensured proper YAML structure when only one cluster, context, or user remains in the kubeconfig file.

### Changed
- **Environment Detection**: Enhanced WSL detection and config path handling for both native Linux/macOS and WSL environments.
- **KubeConfig Path Handling**: Improved logic for determining the kubeconfig path in different environments (Windows, WSL, Linux/macOS).

### Fixed
- **Cluster Removal Formatting**: Fixed an issue where the kubeconfig format would break when cleaning up to a single cluster, context, or user.
- **Cluster Kept Count**: fixed so the number is correct. It was 1 out before.


## [0.0.9] - 2024-09-26

### Fixed
- Fixed exclusion parameter so it is back to `ExclusionList` and not `ExclusionArray`.

## [0.0.8] - 2024-09-26

### Added
- Introduced the `-ListClusters` parameter, allowing users to list all clusters in the kubeconfig file without performing any cleanup.
- Added function `Show-KubeTidyBanner` to display ASCII art and start message as a reusable function.
- Updated main command to `Invoke-KubeTidy` for better clarity and consistency.

### Changed
- Improved documentation to reflect new functionality and renamed the primary function to `Invoke-KubeTidy`.
- Updated README to include examples and instructions for the `-ListClusters` option.

## [0.0.7] - 2024-09-25

### Added
- Verbose output option with the `-Verbose` parameter for detailed logging of operations and cluster checks.
- Backup creation before cleanup to ensure that no data is lost in case of an error during the operation.
- Exclusion list functionality to skip specific clusters from removal using the `-ExclusionList` parameter.

## [0.0.6] - 2024-09-25

### Added
- Initial release of **KubeTidy**, featuring Kubernetes cluster reachability checks and cleanup of unreachable clusters, contexts, and users.