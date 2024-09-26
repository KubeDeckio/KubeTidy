# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

---

### How to Use the Changelog

1. Make sure to increment the version number in the changelog with every new release.
2. Keep the changes concise and organized under headings like "Added", "Changed", "Fixed", and "Removed" to ensure easy tracking of what was done in each version.

