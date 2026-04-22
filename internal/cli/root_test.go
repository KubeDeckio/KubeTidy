package cli

import (
	"bytes"
	"strings"
	"testing"
)

func TestDoctorCommandOutputsJSON(t *testing.T) {
	cmd := NewRootCommand()
	stdout := &bytes.Buffer{}
	stderr := &bytes.Buffer{}
	cmd.SetOut(stdout)
	cmd.SetErr(stderr)
	cmd.SetArgs([]string{
		"doctor",
		"--ui",
		"--output", "json",
		"--kubeconfig", "../kubeconfig/testdata/export-complex.yaml",
	})

	if err := cmd.Execute(); err != nil {
		t.Fatalf("command failed: %v", err)
	}
	if !strings.Contains(stdout.String(), "\"healthy\": true") {
		t.Fatalf("expected healthy doctor JSON output, got %s", stdout.String())
	}
}

func TestCompletionCommandGeneratesPowerShellScript(t *testing.T) {
	cmd := NewRootCommand()
	stdout := &bytes.Buffer{}
	cmd.SetOut(stdout)
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs([]string{"completion", "powershell"})

	if err := cmd.Execute(); err != nil {
		t.Fatalf("command failed: %v", err)
	}
	if !strings.Contains(stdout.String(), "Register-ArgumentCompleter") {
		t.Fatalf("expected PowerShell completion script, got %s", stdout.String())
	}
}

func TestVersionCommandIncludesBuildFields(t *testing.T) {
	origVersion, origCommit, origDate := version, commit, date
	version, commit, date = "1.2.3", "abc123", "2026-04-08T10:00:00Z"
	t.Cleanup(func() {
		version, commit, date = origVersion, origCommit, origDate
	})

	cmd := NewRootCommand()
	stdout := &bytes.Buffer{}
	cmd.SetOut(stdout)
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs([]string{"version"})

	if err := cmd.Execute(); err != nil {
		t.Fatalf("command failed: %v", err)
	}
	output := stdout.String()
	if !strings.Contains(output, "version=1.2.3") || !strings.Contains(output, "commit=abc123") || !strings.Contains(output, "date=2026-04-08T10:00:00Z") {
		t.Fatalf("expected build metadata in version output, got %s", output)
	}
}
