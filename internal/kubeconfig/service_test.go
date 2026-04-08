package kubeconfig

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"k8s.io/client-go/tools/clientcmd"
)

func TestCleanupPreservesRemainingKubeconfigFields(t *testing.T) {
	t.Parallel()

	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer server.Close()

	path := copyFixture(t, "cleanup-complex.yaml")
	replaceAll(t, path, "https://keep.example", server.URL)

	result, err := (Service{}).Cleanup(CleanupOptions{
		Source: ConfigSource{
			Paths:     []string{path},
			WritePath: path,
		},
		Backup:        true,
		Force:         true,
		ProbeTimeout:  time.Second,
		MergeStrategy: MergeStrategyKeepFirst,
	})
	if err != nil {
		t.Fatalf("Cleanup returned error: %v", err)
	}

	updated, err := clientcmd.LoadFromFile(path)
	if err != nil {
		t.Fatalf("failed to load updated kubeconfig: %v", err)
	}

	if len(result.RemovedClusters) != 1 || result.RemovedClusters[0] != "drop" {
		t.Fatalf("expected one removed cluster, got %+v", result.RemovedClusters)
	}
	if _, ok := updated.Clusters["keep"]; !ok {
		t.Fatalf("expected keep cluster to remain")
	}
	if _, ok := updated.Clusters["drop"]; ok {
		t.Fatalf("expected drop cluster to be removed")
	}
	if updated.CurrentContext != "keep-ctx" {
		t.Fatalf("expected current context to be preserved, got %q", updated.CurrentContext)
	}
	if updated.Clusters["keep"].ProxyURL != "socks5://proxy.internal:1080" {
		t.Fatalf("expected proxy URL to be preserved")
	}
	if updated.Clusters["keep"].TLSServerName != "keep.internal" {
		t.Fatalf("expected TLS server name to be preserved")
	}
	if updated.AuthInfos["shared-user"].TokenFile != "/tmp/keep-token" {
		t.Fatalf("expected token file to be preserved")
	}
	if updated.AuthInfos["shared-user"].Exec == nil || updated.AuthInfos["shared-user"].Exec.Command != "aws" {
		t.Fatalf("expected exec auth config to be preserved")
	}
	if _, ok := updated.AuthInfos["drop-user"]; ok {
		t.Fatalf("expected drop user to be removed")
	}
	matches, err := filepath.Glob(path + ".bak_*")
	if err != nil {
		t.Fatalf("failed to glob backup files: %v", err)
	}
	if len(matches) != 1 {
		t.Fatalf("expected one backup file, found %d", len(matches))
	}
}

func TestCleanupDryRunDoesNotWriteChanges(t *testing.T) {
	t.Parallel()

	path := copyFixture(t, "cleanup-complex.yaml")
	before, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read fixture before cleanup: %v", err)
	}

	result, err := (Service{}).Cleanup(CleanupOptions{
		Source: ConfigSource{
			Paths:     []string{path},
			WritePath: path,
		},
		Backup:        true,
		Force:         true,
		DryRun:        true,
		ProbeTimeout:  time.Millisecond,
		MergeStrategy: MergeStrategyKeepFirst,
	})
	if err != nil {
		t.Fatalf("expected dry-run cleanup to succeed, got %v", err)
	}
	if !result.DryRun {
		t.Fatalf("expected dry-run result")
	}

	after, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read fixture after cleanup: %v", err)
	}
	if !bytes.Equal(before, after) {
		t.Fatalf("expected dry-run cleanup to leave kubeconfig unchanged")
	}
}

func TestExportPreservesSelectedContextFields(t *testing.T) {
	t.Parallel()

	source := copyFixture(t, "export-complex.yaml")
	dest := filepath.Join(t.TempDir(), "exported.yaml")

	result, err := (Service{}).Export(ExportOptions{
		SourcePath:      source,
		DestinationPath: dest,
		Contexts:        []string{"team-a"},
		MergeStrategy:   MergeStrategyKeepFirst,
	})
	if err != nil {
		t.Fatalf("Export returned error: %v", err)
	}
	if len(result.ExportedContexts) != 1 || result.ExportedContexts[0] != "team-a" {
		t.Fatalf("expected exported team-a context, got %+v", result.ExportedContexts)
	}

	exported, err := clientcmd.LoadFromFile(dest)
	if err != nil {
		t.Fatalf("failed to load exported kubeconfig: %v", err)
	}
	if len(exported.Contexts) != 1 || exported.CurrentContext != "team-a" {
		t.Fatalf("expected only team-a context and current-context to be preserved")
	}
	if exported.Contexts["team-a"].Namespace != "apps" {
		t.Fatalf("expected context namespace to be preserved")
	}
	if exported.Clusters["team-a-cluster"].TLSServerName != "cluster.internal" {
		t.Fatalf("expected cluster TLS server name to be preserved")
	}
	if exported.Clusters["team-a-cluster"].ProxyURL != "http://proxy.internal:8080" {
		t.Fatalf("expected cluster proxy URL to be preserved")
	}
	if exported.AuthInfos["team-a-user"].Token != "team-a-token" {
		t.Fatalf("expected auth info token to be preserved")
	}
	if len(exported.AuthInfos["team-a-user"].Extensions) != 1 {
		t.Fatalf("expected user extensions to be preserved")
	}
}

func TestMergePreservesDistinctEntriesAndReportsDuplicates(t *testing.T) {
	t.Parallel()

	pathA := copyFixture(t, "merge-first.yaml")
	pathB := copyFixture(t, "merge-second.yaml")
	dest := filepath.Join(t.TempDir(), "merged.yaml")

	summary, err := (Service{}).Merge(MergeOptions{
		Paths:       []string{pathA, pathB},
		Destination: dest,
		Strategy:    MergeStrategyKeepFirst,
	})
	if err != nil {
		t.Fatalf("Merge returned error: %v", err)
	}

	merged, err := clientcmd.LoadFromFile(dest)
	if err != nil {
		t.Fatalf("failed to load merged kubeconfig: %v", err)
	}
	if summary.DuplicateClusters != 1 || summary.DuplicateContexts != 1 || summary.DuplicateUsers != 1 {
		t.Fatalf("expected duplicate counts to be reported, got %+v", summary)
	}
	if merged.CurrentContext != "alpha" {
		t.Fatalf("expected first current-context to win, got %q", merged.CurrentContext)
	}
	if merged.Clusters["shared-cluster"].Server != "https://alpha.example" {
		t.Fatalf("expected first duplicate cluster to win")
	}
	if merged.AuthInfos["shared-user"].Exec == nil || merged.AuthInfos["shared-user"].Exec.Command != "aws" {
		t.Fatalf("expected first duplicate user to win")
	}
}

func TestMergeKeepLastWins(t *testing.T) {
	t.Parallel()

	pathA := copyFixture(t, "merge-first.yaml")
	pathB := copyFixture(t, "merge-second.yaml")
	dest := filepath.Join(t.TempDir(), "merged.yaml")

	_, err := (Service{}).Merge(MergeOptions{
		Paths:       []string{pathA, pathB},
		Destination: dest,
		Strategy:    MergeStrategyKeepLast,
	})
	if err != nil {
		t.Fatalf("Merge returned error: %v", err)
	}

	merged, err := clientcmd.LoadFromFile(dest)
	if err != nil {
		t.Fatalf("failed to load merged kubeconfig: %v", err)
	}
	if merged.Clusters["shared-cluster"].Server != "https://beta-overwrite.example" {
		t.Fatalf("expected keep-last strategy to overwrite duplicate cluster")
	}
	if merged.AuthInfos["shared-user"].Token != "should-not-win" {
		t.Fatalf("expected keep-last strategy to overwrite duplicate user")
	}
}

func TestMergeFailOnConflictReturnsError(t *testing.T) {
	t.Parallel()

	pathA := copyFixture(t, "merge-first.yaml")
	pathB := copyFixture(t, "merge-second.yaml")

	_, err := (Service{}).Merge(MergeOptions{
		Paths:       []string{pathA, pathB},
		Destination: filepath.Join(t.TempDir(), "merged.yaml"),
		Strategy:    MergeStrategyFailOnConflict,
	})
	if err == nil {
		t.Fatalf("expected conflict error for fail-on-conflict strategy")
	}
}

func TestResolveSourceUsesFirstKubeconfigEntry(t *testing.T) {
	first := filepath.Join(t.TempDir(), "first")
	second := filepath.Join(t.TempDir(), "second")
	separator := string(os.PathListSeparator)

	t.Setenv("KUBECONFIG", first+separator+second)
	source, err := ResolveSource("")
	if err != nil {
		t.Fatalf("ResolveSource returned error: %v", err)
	}
	if source.WritePath != first || len(source.Paths) != 2 || !source.MultiFile {
		t.Fatalf("expected first KUBECONFIG entry and multi-file source, got %+v", source)
	}
}

func TestReportDetectsDuplicateServersAndOrphans(t *testing.T) {
	t.Parallel()

	pathA := copyFixture(t, "merge-first.yaml")
	pathB := copyFixture(t, "merge-second.yaml")
	report, err := (Service{}).Report(ConfigSource{
		Paths:     []string{pathA, pathB},
		WritePath: pathA,
		MultiFile: true,
	}, MergeStrategyKeepFirst)
	if err != nil {
		t.Fatalf("Report returned error: %v", err)
	}
	if report.ClusterCount != 3 || report.SourceDuplicateClusters != 1 {
		t.Fatalf("expected report to count merged clusters and duplicates, got %+v", report)
	}
}

func TestDoctorReportsHealthIssues(t *testing.T) {
	t.Parallel()

	pathA := copyFixture(t, "merge-first.yaml")
	pathB := copyFixture(t, "merge-second.yaml")
	result, err := (Service{}).Doctor(ConfigSource{
		Paths:     []string{pathA, pathB},
		WritePath: pathA,
		MultiFile: true,
	}, MergeStrategyKeepFirst)
	if err != nil {
		t.Fatalf("Doctor returned error: %v", err)
	}
	if result.Healthy {
		t.Fatalf("expected doctor to find issues")
	}
	if result.IssueCount == 0 || result.WarningCount == 0 {
		t.Fatalf("expected doctor warnings, got %+v", result)
	}
}

func TestDoctorHealthyConfig(t *testing.T) {
	t.Parallel()

	path := copyFixture(t, "export-complex.yaml")
	result, err := (Service{}).Doctor(ConfigSource{
		Paths:     []string{path},
		WritePath: path,
	}, MergeStrategyKeepFirst)
	if err != nil {
		t.Fatalf("Doctor returned error: %v", err)
	}
	if !result.Healthy {
		t.Fatalf("expected healthy config, got %+v", result)
	}
	if result.IssueCount != 0 {
		t.Fatalf("expected no issues, got %+v", result)
	}
}

func copyFixture(t *testing.T, name string) string {
	t.Helper()
	src := filepath.Join("testdata", name)
	content, err := os.ReadFile(src)
	if err != nil {
		t.Fatalf("failed to read fixture %s: %v", name, err)
	}
	dst := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(dst, content, 0o600); err != nil {
		t.Fatalf("failed to write fixture copy %s: %v", name, err)
	}
	return dst
}

func replaceAll(t *testing.T, path, oldValue, newValue string) {
	t.Helper()
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read %s: %v", path, err)
	}
	updated := bytes.ReplaceAll(content, []byte(oldValue), []byte(newValue))
	if err := os.WriteFile(path, updated, 0o600); err != nil {
		t.Fatalf("failed to write %s: %v", path, err)
	}
}
