package kubeconfig

import (
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"runtime"
	"slices"
	"strings"
	"time"

	"k8s.io/client-go/tools/clientcmd"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
)

type MergeStrategy string

const (
	MergeStrategyKeepFirst      MergeStrategy = "keep-first"
	MergeStrategyKeepLast       MergeStrategy = "keep-last"
	MergeStrategyFailOnConflict MergeStrategy = "fail-on-conflict"
)

type ConfigSource struct {
	Paths      []string `json:"paths" yaml:"paths"`
	WritePath  string   `json:"writePath" yaml:"writePath"`
	Explicit   bool     `json:"explicit" yaml:"explicit"`
	MultiFile  bool     `json:"multiFile" yaml:"multiFile"`
	FromEnvVar bool     `json:"fromEnvVar" yaml:"fromEnvVar"`
}

type Service struct {
	Logf func(format string, values ...any)
	Out  io.Writer
}

type CleanupOptions struct {
	Source        ConfigSource
	ExclusionList []string
	Backup        bool
	Force         bool
	DryRun        bool
	ProbeTimeout  time.Duration
	MergeStrategy MergeStrategy
}

type CleanupResult struct {
	Source                ConfigSource `json:"source" yaml:"source"`
	CheckedClusters       int          `json:"checkedClusters" yaml:"checkedClusters"`
	ReachableClusters     int          `json:"reachableClusters" yaml:"reachableClusters"`
	RemovedClusters       []string     `json:"removedClusters" yaml:"removedClusters"`
	RemovedContexts       []string     `json:"removedContexts" yaml:"removedContexts"`
	RemovedUsers          []string     `json:"removedUsers" yaml:"removedUsers"`
	SkippedClusters       []string     `json:"skippedClusters" yaml:"skippedClusters"`
	BackupPath            string       `json:"backupPath,omitempty" yaml:"backupPath,omitempty"`
	CurrentContext        string       `json:"currentContext,omitempty" yaml:"currentContext,omitempty"`
	CurrentContextCleared bool         `json:"currentContextCleared" yaml:"currentContextCleared"`
	DryRun                bool         `json:"dryRun" yaml:"dryRun"`
	ProbeTimeoutSeconds   int          `json:"probeTimeoutSeconds" yaml:"probeTimeoutSeconds"`
}

type ExportOptions struct {
	SourcePath      string        `json:"sourcePath" yaml:"sourcePath"`
	DestinationPath string        `json:"destinationPath" yaml:"destinationPath"`
	Contexts        []string      `json:"contexts" yaml:"contexts"`
	MergeStrategy   MergeStrategy `json:"mergeStrategy" yaml:"mergeStrategy"`
}

type ExportResult struct {
	SourcePath       string   `json:"sourcePath" yaml:"sourcePath"`
	DestinationPath  string   `json:"destinationPath" yaml:"destinationPath"`
	ExportedContexts []string `json:"exportedContexts" yaml:"exportedContexts"`
	MissingContexts  []string `json:"missingContexts,omitempty" yaml:"missingContexts,omitempty"`
	CurrentContext   string   `json:"currentContext,omitempty" yaml:"currentContext,omitempty"`
}

type MergeOptions struct {
	Paths       []string      `json:"paths" yaml:"paths"`
	Destination string        `json:"destination" yaml:"destination"`
	DryRun      bool          `json:"dryRun" yaml:"dryRun"`
	Strategy    MergeStrategy `json:"strategy" yaml:"strategy"`
}

type MergeSummary struct {
	Destination       string   `json:"destination" yaml:"destination"`
	Strategy          string   `json:"strategy" yaml:"strategy"`
	FilesMerged       int      `json:"filesMerged" yaml:"filesMerged"`
	ClustersMerged    int      `json:"clustersMerged" yaml:"clustersMerged"`
	ContextsMerged    int      `json:"contextsMerged" yaml:"contextsMerged"`
	UsersMerged       int      `json:"usersMerged" yaml:"usersMerged"`
	DuplicateClusters int      `json:"duplicateClusters" yaml:"duplicateClusters"`
	DuplicateContexts int      `json:"duplicateContexts" yaml:"duplicateContexts"`
	DuplicateUsers    int      `json:"duplicateUsers" yaml:"duplicateUsers"`
	SkippedClusters   []string `json:"skippedClusters,omitempty" yaml:"skippedClusters,omitempty"`
	SkippedContexts   []string `json:"skippedContexts,omitempty" yaml:"skippedContexts,omitempty"`
	SkippedUsers      []string `json:"skippedUsers,omitempty" yaml:"skippedUsers,omitempty"`
	DryRun            bool     `json:"dryRun" yaml:"dryRun"`
}

type ListClustersResult struct {
	Source   ConfigSource `json:"source" yaml:"source"`
	Clusters []string     `json:"clusters" yaml:"clusters"`
}

type ListContextsResult struct {
	Source         ConfigSource `json:"source" yaml:"source"`
	Contexts       []string     `json:"contexts" yaml:"contexts"`
	CurrentContext string       `json:"currentContext,omitempty" yaml:"currentContext,omitempty"`
}

type ReportResult struct {
	Source                  ConfigSource        `json:"source" yaml:"source"`
	MergeStrategy           string              `json:"mergeStrategy" yaml:"mergeStrategy"`
	CurrentContext          string              `json:"currentContext,omitempty" yaml:"currentContext,omitempty"`
	CurrentContextMissing   bool                `json:"currentContextMissing" yaml:"currentContextMissing"`
	ClusterCount            int                 `json:"clusterCount" yaml:"clusterCount"`
	ContextCount            int                 `json:"contextCount" yaml:"contextCount"`
	UserCount               int                 `json:"userCount" yaml:"userCount"`
	OrphanedContexts        []string            `json:"orphanedContexts,omitempty" yaml:"orphanedContexts,omitempty"`
	UnusedUsers             []string            `json:"unusedUsers,omitempty" yaml:"unusedUsers,omitempty"`
	DuplicateServerGroups   map[string][]string `json:"duplicateServerGroups,omitempty" yaml:"duplicateServerGroups,omitempty"`
	SourceDuplicateClusters int                 `json:"sourceDuplicateClusters" yaml:"sourceDuplicateClusters"`
	SourceDuplicateContexts int                 `json:"sourceDuplicateContexts" yaml:"sourceDuplicateContexts"`
	SourceDuplicateUsers    int                 `json:"sourceDuplicateUsers" yaml:"sourceDuplicateUsers"`
}

type DoctorIssue struct {
	Severity string `json:"severity" yaml:"severity"`
	Category string `json:"category" yaml:"category"`
	Message  string `json:"message" yaml:"message"`
}

type DoctorResult struct {
	Report        ReportResult  `json:"report" yaml:"report"`
	Healthy       bool          `json:"healthy" yaml:"healthy"`
	IssueCount    int           `json:"issueCount" yaml:"issueCount"`
	WarningCount  int           `json:"warningCount" yaml:"warningCount"`
	CriticalCount int           `json:"criticalCount" yaml:"criticalCount"`
	Issues        []DoctorIssue `json:"issues,omitempty" yaml:"issues,omitempty"`
}

type loadSummary struct {
	duplicateClusters int
	duplicateContexts int
	duplicateUsers    int
	skippedClusters   []string
	skippedContexts   []string
	skippedUsers      []string
}

func NormalizeMergeStrategy(value string) (MergeStrategy, error) {
	switch MergeStrategy(strings.TrimSpace(value)) {
	case "", MergeStrategyKeepFirst:
		return MergeStrategyKeepFirst, nil
	case MergeStrategyKeepLast:
		return MergeStrategyKeepLast, nil
	case MergeStrategyFailOnConflict:
		return MergeStrategyFailOnConflict, nil
	default:
		return "", fmt.Errorf("invalid merge strategy %q", value)
	}
}

func (s Service) logf(format string, values ...any) {
	if s.Logf != nil {
		s.Logf(format, values...)
	}
}

func ResolveSource(provided string) (ConfigSource, error) {
	if strings.TrimSpace(provided) != "" {
		paths := cleanPaths(filepath.SplitList(provided))
		if len(paths) == 0 {
			return ConfigSource{}, fmt.Errorf("no kubeconfig paths provided")
		}
		return ConfigSource{
			Paths:     paths,
			WritePath: paths[0],
			Explicit:  true,
			MultiFile: len(paths) > 1,
		}, nil
	}

	if env := strings.TrimSpace(os.Getenv("KUBECONFIG")); env != "" {
		paths := cleanPaths(filepath.SplitList(env))
		if len(paths) > 0 {
			return ConfigSource{
				Paths:      paths,
				WritePath:  paths[0],
				MultiFile:  len(paths) > 1,
				FromEnvVar: true,
			}, nil
		}
	}

	if runtime.GOOS == "linux" {
		if wslPath, err := resolveWSLWindowsConfig(); err == nil && wslPath != "" {
			return ConfigSource{
				Paths:     []string{wslPath},
				WritePath: wslPath,
			}, nil
		}
	}

	return ConfigSource{
		Paths:     []string{clientcmd.RecommendedHomeFile},
		WritePath: clientcmd.RecommendedHomeFile,
	}, nil
}

func DefaultFilteredConfigPath() string {
	return filepath.Join(filepath.Dir(clientcmd.RecommendedHomeFile), "filtered-config")
}

func (s Service) ListClusters(source ConfigSource, strategy MergeStrategy) (ListClustersResult, error) {
	cfg, _, err := s.loadConfig(source.Paths, strategy)
	if err != nil {
		return ListClustersResult{}, err
	}

	names := make([]string, 0, len(cfg.Clusters))
	for name := range cfg.Clusters {
		names = append(names, name)
	}
	slices.Sort(names)

	return ListClustersResult{
		Source:   source,
		Clusters: names,
	}, nil
}

func (s Service) ListContexts(source ConfigSource, strategy MergeStrategy) (ListContextsResult, error) {
	cfg, _, err := s.loadConfig(source.Paths, strategy)
	if err != nil {
		return ListContextsResult{}, err
	}

	names := make([]string, 0, len(cfg.Contexts))
	for name := range cfg.Contexts {
		names = append(names, name)
	}
	slices.Sort(names)

	return ListContextsResult{
		Source:         source,
		Contexts:       names,
		CurrentContext: cfg.CurrentContext,
	}, nil
}

func (s Service) Report(source ConfigSource, strategy MergeStrategy) (ReportResult, error) {
	cfg, summary, err := s.loadConfig(source.Paths, strategy)
	if err != nil {
		return ReportResult{}, err
	}

	referencedUsers := make(map[string]struct{})
	orphanedContexts := make([]string, 0)
	for name, ctx := range cfg.Contexts {
		_, clusterExists := cfg.Clusters[ctx.Cluster]
		_, userExists := cfg.AuthInfos[ctx.AuthInfo]
		if !clusterExists || !userExists {
			orphanedContexts = append(orphanedContexts, name)
		}
		if ctx.AuthInfo != "" {
			referencedUsers[ctx.AuthInfo] = struct{}{}
		}
	}
	slices.Sort(orphanedContexts)

	unusedUsers := make([]string, 0)
	for name := range cfg.AuthInfos {
		if _, used := referencedUsers[name]; !used {
			unusedUsers = append(unusedUsers, name)
		}
	}
	slices.Sort(unusedUsers)

	serverGroups := make(map[string][]string)
	for name, cluster := range cfg.Clusters {
		serverGroups[cluster.Server] = append(serverGroups[cluster.Server], name)
	}
	duplicateServerGroups := make(map[string][]string)
	for server, names := range serverGroups {
		if len(names) > 1 {
			slices.Sort(names)
			duplicateServerGroups[server] = names
		}
	}

	currentContextMissing := false
	if cfg.CurrentContext != "" {
		if _, ok := cfg.Contexts[cfg.CurrentContext]; !ok {
			currentContextMissing = true
		}
	}

	return ReportResult{
		Source:                  source,
		MergeStrategy:           string(strategy),
		CurrentContext:          cfg.CurrentContext,
		CurrentContextMissing:   currentContextMissing,
		ClusterCount:            len(cfg.Clusters),
		ContextCount:            len(cfg.Contexts),
		UserCount:               len(cfg.AuthInfos),
		OrphanedContexts:        orphanedContexts,
		UnusedUsers:             unusedUsers,
		DuplicateServerGroups:   duplicateServerGroups,
		SourceDuplicateClusters: summary.duplicateClusters,
		SourceDuplicateContexts: summary.duplicateContexts,
		SourceDuplicateUsers:    summary.duplicateUsers,
	}, nil
}

func (s Service) Doctor(source ConfigSource, strategy MergeStrategy) (DoctorResult, error) {
	report, err := s.Report(source, strategy)
	if err != nil {
		return DoctorResult{}, err
	}

	issues := make([]DoctorIssue, 0)
	warningCount := 0
	criticalCount := 0

	addIssue := func(severity, category, message string) {
		issues = append(issues, DoctorIssue{
			Severity: severity,
			Category: category,
			Message:  message,
		})
		switch severity {
		case "critical":
			criticalCount++
		case "warning":
			warningCount++
		}
	}

	if report.CurrentContextMissing {
		addIssue("critical", "current-context", fmt.Sprintf("Current context %q is missing from the merged view.", report.CurrentContext))
	}
	for _, name := range report.OrphanedContexts {
		addIssue("critical", "orphaned-context", fmt.Sprintf("Context %q points to a missing cluster or user.", name))
	}
	for _, name := range report.UnusedUsers {
		addIssue("warning", "unused-user", fmt.Sprintf("User %q is not referenced by any context.", name))
	}
	for server, names := range report.DuplicateServerGroups {
		addIssue("warning", "duplicate-server", fmt.Sprintf("Server %q is shared by multiple clusters: %s.", server, strings.Join(names, ", ")))
	}
	if report.SourceDuplicateClusters > 0 {
		addIssue("warning", "duplicate-cluster-name", fmt.Sprintf("Found %d duplicate cluster name collisions while loading source files.", report.SourceDuplicateClusters))
	}
	if report.SourceDuplicateContexts > 0 {
		addIssue("warning", "duplicate-context-name", fmt.Sprintf("Found %d duplicate context name collisions while loading source files.", report.SourceDuplicateContexts))
	}
	if report.SourceDuplicateUsers > 0 {
		addIssue("warning", "duplicate-user-name", fmt.Sprintf("Found %d duplicate user name collisions while loading source files.", report.SourceDuplicateUsers))
	}

	return DoctorResult{
		Report:        report,
		Healthy:       len(issues) == 0,
		IssueCount:    len(issues),
		WarningCount:  warningCount,
		CriticalCount: criticalCount,
		Issues:        issues,
	}, nil
}

func (s Service) Export(opts ExportOptions) (ExportResult, error) {
	source, err := ResolveSource(opts.SourcePath)
	if err != nil {
		return ExportResult{}, err
	}
	cfg, _, err := s.loadConfig(source.Paths, opts.MergeStrategy)
	if err != nil {
		return ExportResult{}, err
	}
	if len(opts.Contexts) == 0 {
		return ExportResult{}, fmt.Errorf("no contexts specified or invalid context list")
	}

	out := clientcmdapi.NewConfig()
	out.Kind = "Config"
	out.APIVersion = "v1"
	out.Preferences = cfg.Preferences
	out.Extensions = cfg.Extensions

	var exported []string
	var missing []string
	for _, name := range opts.Contexts {
		ctx, ok := cfg.Contexts[name]
		if !ok {
			missing = append(missing, name)
			continue
		}
		exported = append(exported, name)
		out.Contexts[name] = ctx.DeepCopy()
		if cluster, ok := cfg.Clusters[ctx.Cluster]; ok {
			out.Clusters[ctx.Cluster] = cluster.DeepCopy()
		}
		if user, ok := cfg.AuthInfos[ctx.AuthInfo]; ok {
			out.AuthInfos[ctx.AuthInfo] = user.DeepCopy()
		}
	}

	if len(out.Contexts) == 0 {
		return ExportResult{}, fmt.Errorf("no matching contexts were found")
	}
	if _, ok := out.Contexts[cfg.CurrentContext]; ok {
		out.CurrentContext = cfg.CurrentContext
	}
	slices.Sort(exported)
	slices.Sort(missing)

	if err := clientcmd.WriteToFile(*out, opts.DestinationPath); err != nil {
		return ExportResult{}, err
	}

	return ExportResult{
		SourcePath:       strings.Join(source.Paths, string(os.PathListSeparator)),
		DestinationPath:  opts.DestinationPath,
		ExportedContexts: exported,
		MissingContexts:  missing,
		CurrentContext:   out.CurrentContext,
	}, nil
}

func (s Service) Merge(opts MergeOptions) (MergeSummary, error) {
	cfg, summary, err := s.loadConfig(opts.Paths, opts.Strategy)
	if err != nil {
		return MergeSummary{}, err
	}

	result := MergeSummary{
		Destination:       opts.Destination,
		Strategy:          string(opts.Strategy),
		FilesMerged:       len(cleanPaths(opts.Paths)),
		ClustersMerged:    len(cfg.Clusters),
		ContextsMerged:    len(cfg.Contexts),
		UsersMerged:       len(cfg.AuthInfos),
		DuplicateClusters: summary.duplicateClusters,
		DuplicateContexts: summary.duplicateContexts,
		DuplicateUsers:    summary.duplicateUsers,
		SkippedClusters:   sortedUnique(summary.skippedClusters),
		SkippedContexts:   sortedUnique(summary.skippedContexts),
		SkippedUsers:      sortedUnique(summary.skippedUsers),
		DryRun:            opts.DryRun,
	}

	if !opts.DryRun {
		if err := clientcmd.WriteToFile(*cfg, opts.Destination); err != nil {
			return MergeSummary{}, err
		}
	}

	return result, nil
}

func (s Service) Cleanup(opts CleanupOptions) (CleanupResult, error) {
	cfg, _, err := s.loadConfig(opts.Source.Paths, opts.MergeStrategy)
	if err != nil {
		return CleanupResult{}, err
	}

	result := CleanupResult{
		Source:              opts.Source,
		CurrentContext:      cfg.CurrentContext,
		DryRun:              opts.DryRun,
		ProbeTimeoutSeconds: int(resolveProbeTimeout(opts.ProbeTimeout).Seconds()),
	}

	if opts.Backup && !opts.DryRun {
		backupPath, err := backupFile(opts.Source.WritePath)
		if err != nil {
			return CleanupResult{}, fmt.Errorf("failed to create a backup of the KubeConfig file: %w", err)
		}
		result.BackupPath = backupPath
		s.logf("Backup of KubeConfig created at path: %s", backupPath)
	}

	excluded := make(map[string]struct{}, len(opts.ExclusionList))
	for _, item := range opts.ExclusionList {
		item = strings.TrimSpace(item)
		if item != "" {
			excluded[item] = struct{}{}
		}
	}

	type probeOutcome struct {
		clusterName string
		reachable   bool
		skipped     bool
	}

	clusterNames := make([]string, 0, len(cfg.Clusters))
	for name := range cfg.Clusters {
		clusterNames = append(clusterNames, name)
	}
	slices.Sort(clusterNames)
	result.CheckedClusters = len(clusterNames)

	outcomes := make(chan probeOutcome, len(clusterNames))
	for _, name := range clusterNames {
		cluster := cfg.Clusters[name]
		if _, skip := excluded[name]; skip {
			outcomes <- probeOutcome{clusterName: name, skipped: true}
			continue
		}

		go func(clusterName, server string) {
			s.logf("Checking reachability for cluster: %s at %s", clusterName, server)
			outcomes <- probeOutcome{
				clusterName: clusterName,
				reachable:   reachable(server, resolveProbeTimeout(opts.ProbeTimeout)),
			}
		}(name, cluster.Server)
	}

	var removedClusters []string
	for range clusterNames {
		outcome := <-outcomes
		if outcome.skipped {
			result.SkippedClusters = append(result.SkippedClusters, outcome.clusterName)
			s.logf("Skipping cluster %s as it is in the exclusion list.", outcome.clusterName)
			continue
		}
		if outcome.reachable {
			result.ReachableClusters++
			s.logf("%s is reachable via HTTPS.", outcome.clusterName)
			continue
		}
		removedClusters = append(removedClusters, outcome.clusterName)
		s.logf("%s is NOT reachable via HTTPS. Marking for removal.", outcome.clusterName)
	}

	if result.ReachableClusters == 0 && !opts.Force {
		return CleanupResult{}, fmt.Errorf("no clusters are reachable. Perhaps the internet is down? Use `-Force` to proceed with cleanup")
	}

	slices.Sort(removedClusters)
	result.RemovedClusters = removedClusters

	removedSet := make(map[string]struct{}, len(removedClusters))
	removedUsers := make(map[string]struct{})
	removedContexts := make(map[string]struct{})
	for _, name := range removedClusters {
		removedSet[name] = struct{}{}
	}

	for name, ctx := range cfg.Contexts {
		if _, removedCluster := removedSet[ctx.Cluster]; removedCluster {
			removedContexts[name] = struct{}{}
			if ctx.AuthInfo != "" {
				removedUsers[ctx.AuthInfo] = struct{}{}
			}
		}
	}

	for name := range removedContexts {
		result.RemovedContexts = append(result.RemovedContexts, name)
	}
	for name := range removedUsers {
		result.RemovedUsers = append(result.RemovedUsers, name)
	}
	slices.Sort(result.RemovedContexts)
	slices.Sort(result.RemovedUsers)

	if len(removedClusters) == 0 || opts.DryRun {
		return result, nil
	}

	for _, name := range removedClusters {
		delete(cfg.Clusters, name)
	}
	for name := range removedContexts {
		delete(cfg.Contexts, name)
	}
	for name := range removedUsers {
		delete(cfg.AuthInfos, name)
	}
	if _, removedCurrent := removedContexts[cfg.CurrentContext]; removedCurrent {
		s.logf("The current context (%s) belongs to a removed cluster. Unsetting current-context.", cfg.CurrentContext)
		cfg.CurrentContext = ""
		result.CurrentContextCleared = true
	}

	if err := clientcmd.WriteToFile(*cfg, opts.Source.WritePath); err != nil {
		return CleanupResult{}, err
	}

	return result, nil
}

func resolveProbeTimeout(timeout time.Duration) time.Duration {
	if timeout <= 0 {
		return 5 * time.Second
	}
	return timeout
}

func reachable(server string, timeout time.Duration) bool {
	if _, err := url.ParseRequestURI(server); err != nil {
		return false
	}

	client := &http.Client{
		Timeout: timeout,
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		},
	}

	req, err := http.NewRequest(http.MethodHead, server, nil)
	if err != nil {
		return false
	}
	resp, err := client.Do(req)
	if err == nil {
		_ = resp.Body.Close()
		if resp.StatusCode != http.StatusMethodNotAllowed && resp.StatusCode != http.StatusNotImplemented {
			return true
		}
	}

	req, err = http.NewRequest(http.MethodGet, server, nil)
	if err != nil {
		return false
	}
	resp, err = client.Do(req)
	if err != nil {
		return false
	}
	_ = resp.Body.Close()
	return true
}

func backupFile(path string) (string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	backupPath := fmt.Sprintf("%s.bak_%s", path, time.Now().Format("20060102_150405"))
	if err := os.WriteFile(backupPath, content, 0o600); err != nil {
		return "", err
	}
	return backupPath, nil
}

func resolveWSLWindowsConfig() (string, error) {
	versionInfo, err := os.ReadFile("/proc/version")
	if err != nil || !strings.Contains(strings.ToLower(string(versionInfo)), "microsoft") {
		return "", fmt.Errorf("not running under WSL")
	}

	userProfileRaw, err := exec.Command("wslvar", "USERPROFILE").Output()
	if err != nil {
		return "", err
	}
	userProfile := strings.TrimSpace(string(userProfileRaw))
	wslPathRaw, err := exec.Command("wslpath", userProfile).Output()
	if err != nil {
		return "", err
	}
	return filepath.Join(strings.TrimSpace(string(wslPathRaw)), ".kube", "config"), nil
}

func (s Service) loadConfig(paths []string, strategy MergeStrategy) (*clientcmdapi.Config, loadSummary, error) {
	cleanedPaths := cleanPaths(paths)
	if len(cleanedPaths) == 0 {
		return nil, loadSummary{}, fmt.Errorf("no kubeconfig paths provided")
	}
	if len(cleanedPaths) == 1 {
		cfg, err := clientcmd.LoadFromFile(cleanedPaths[0])
		return cfg, loadSummary{}, err
	}

	merged := clientcmdapi.NewConfig()
	merged.Kind = "Config"
	merged.APIVersion = "v1"
	merged.Preferences = clientcmdapi.Preferences{}
	summary := loadSummary{}

	for _, path := range cleanedPaths {
		s.logf("Loading kubeconfig from %s", path)
		cfg, err := clientcmd.LoadFromFile(path)
		if err != nil {
			return nil, loadSummary{}, err
		}
		if merged.CurrentContext == "" && cfg.CurrentContext != "" {
			merged.CurrentContext = cfg.CurrentContext
		}
		if err := mergeClusters(merged.Clusters, cfg.Clusters, strategy, &summary); err != nil {
			return nil, loadSummary{}, err
		}
		if err := mergeContexts(merged.Contexts, cfg.Contexts, strategy, &summary); err != nil {
			return nil, loadSummary{}, err
		}
		if err := mergeUsers(merged.AuthInfos, cfg.AuthInfos, strategy, &summary); err != nil {
			return nil, loadSummary{}, err
		}
		if len(merged.Extensions) == 0 {
			merged.Extensions = cfg.Extensions
		}
	}

	return merged, summary, nil
}

func mergeClusters(target, source map[string]*clientcmdapi.Cluster, strategy MergeStrategy, summary *loadSummary) error {
	for name, incoming := range source {
		if existing, ok := target[name]; ok {
			summary.duplicateClusters++
			switch strategy {
			case MergeStrategyKeepFirst:
				summary.skippedClusters = append(summary.skippedClusters, name)
			case MergeStrategyKeepLast:
				target[name] = incoming.DeepCopy()
			case MergeStrategyFailOnConflict:
				if !reflect.DeepEqual(existing, incoming) {
					return fmt.Errorf("merge conflict for cluster %q", name)
				}
			default:
				return fmt.Errorf("unsupported merge strategy %q", strategy)
			}
			continue
		}
		target[name] = incoming.DeepCopy()
	}
	return nil
}

func mergeContexts(target, source map[string]*clientcmdapi.Context, strategy MergeStrategy, summary *loadSummary) error {
	for name, incoming := range source {
		if existing, ok := target[name]; ok {
			summary.duplicateContexts++
			switch strategy {
			case MergeStrategyKeepFirst:
				summary.skippedContexts = append(summary.skippedContexts, name)
			case MergeStrategyKeepLast:
				target[name] = incoming.DeepCopy()
			case MergeStrategyFailOnConflict:
				if !reflect.DeepEqual(existing, incoming) {
					return fmt.Errorf("merge conflict for context %q", name)
				}
			default:
				return fmt.Errorf("unsupported merge strategy %q", strategy)
			}
			continue
		}
		target[name] = incoming.DeepCopy()
	}
	return nil
}

func mergeUsers(target, source map[string]*clientcmdapi.AuthInfo, strategy MergeStrategy, summary *loadSummary) error {
	for name, incoming := range source {
		if existing, ok := target[name]; ok {
			summary.duplicateUsers++
			switch strategy {
			case MergeStrategyKeepFirst:
				summary.skippedUsers = append(summary.skippedUsers, name)
			case MergeStrategyKeepLast:
				target[name] = incoming.DeepCopy()
			case MergeStrategyFailOnConflict:
				if !reflect.DeepEqual(existing, incoming) {
					return fmt.Errorf("merge conflict for user %q", name)
				}
			default:
				return fmt.Errorf("unsupported merge strategy %q", strategy)
			}
			continue
		}
		target[name] = incoming.DeepCopy()
	}
	return nil
}

func cleanPaths(paths []string) []string {
	out := make([]string, 0, len(paths))
	for _, path := range paths {
		path = strings.TrimSpace(path)
		if path == "" {
			continue
		}
		out = append(out, filepath.Clean(path))
	}
	return out
}

func sortedUnique(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(values))
	out := make([]string, 0, len(values))
	for _, value := range values {
		if _, exists := seen[value]; exists {
			continue
		}
		seen[value] = struct{}{}
		out = append(out, value)
	}
	slices.Sort(out)
	return out
}
