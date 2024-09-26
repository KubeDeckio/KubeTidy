# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.12] - 2024-10-01

### Added
- **Dry Run Mode:** Introduced the `-DryRun` parameter, allowing users to simulate cleanup and merging processes without making any changes. This provides a preview of actions KubeTidy would perform.

## [0.0.11] - 2024-09-30

### Added
- **Merge Kubeconfig Files:** Introduced the ability to merge multiple kubeconfig files into one using the `-MergeConfigs` parameter. Users can specify multiple kubeconfig file paths to be merged into the destination kubeconfig file.
- **DestinationConfig Parameter:** Added the `-DestinationConfig` parameter for specifying the output path of the merged kubeconfig file. If not specified, it defaults to `"$HOME/.kube/config"`.
- **Cluster Count Output:** The `-ListClusters` parameter now also outputs the total number of clusters present in the kubeconfig file after listing them.

## [0.0.10] - 2024-09-28

### Added
- Initial support for listing clusters with `-ListClusters` to display all clusters in the kubeconfig file without performing any cleanup.
- Added functionality to retain users and contexts during the cleanup process when clusters are marked for removal.

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
