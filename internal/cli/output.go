package cli

import (
	"encoding/json"
	"fmt"
	"io"
	"strings"

	"github.com/KubeDeckio/KubeTidy/internal/kubeconfig"
	"sigs.k8s.io/yaml"
)

type outputMode string

const (
	outputText outputMode = "text"
	outputJSON outputMode = "json"
	outputYAML outputMode = "yaml"
)

const (
	colorReset      = "\033[0m"
	colorYellow     = "\033[33m"
	colorGreen      = "\033[32m"
	colorRed        = "\033[31m"
	colorMagenta    = "\033[35m"
	colorBrightCyan = "\033[1;38;5;45m"
)

func normalizeOutput(value string) outputMode {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", string(outputText):
		return outputText
	case string(outputJSON):
		return outputJSON
	case string(outputYAML):
		return outputYAML
	default:
		return outputText
	}
}

func renderOutput(out io.Writer, mode outputMode, value any) error {
	switch mode {
	case outputJSON:
		encoded, err := json.MarshalIndent(value, "", "  ")
		if err != nil {
			return err
		}
		_, err = fmt.Fprintln(out, string(encoded))
		return err
	case outputYAML:
		encoded, err := yaml.Marshal(value)
		if err != nil {
			return err
		}
		_, err = fmt.Fprintln(out, string(encoded))
		return err
	default:
		return renderText(out, value)
	}
}

func renderText(out io.Writer, value any) error {
	switch result := value.(type) {
	case kubeconfig.ListClustersResult:
		writeLine(out, colorYellow, "Listing all clusters in KubeConfig file:")
		fmt.Fprintln(out)
		for _, name := range result.Clusters {
			fmt.Fprintf(out, "%sCluster:%s %s\n", colorBrightCyan, colorReset, name)
		}
		fmt.Fprintln(out)
		fmt.Fprintf(out, "%sTotal Clusters:%s %d\n", colorGreen, colorReset, len(result.Clusters))
	case kubeconfig.ListContextsResult:
		writeLine(out, colorYellow, "Listing all contexts in Kubeconfig file:")
		fmt.Fprintln(out)
		for _, name := range result.Contexts {
			fmt.Fprintf(out, "%sContext:%s %s\n", colorBrightCyan, colorReset, name)
		}
		if result.CurrentContext != "" {
			fmt.Fprintf(out, "\n%sCurrent context:%s %s\n", colorGreen, colorReset, result.CurrentContext)
		} else {
			writeLine(out, colorRed, "\nNo current context is set.")
		}
		fmt.Fprintln(out)
		fmt.Fprintf(out, "%sTotal number of contexts:%s %d\n", colorGreen, colorReset, len(result.Contexts))
	case kubeconfig.ExportResult:
		for _, name := range result.MissingContexts {
			fmt.Fprintf(out, "%sContext %s not found in the kubeconfig.%s\n", colorRed, name, colorReset)
		}
		fmt.Fprintf(out, "\n%sFiltered kubeconfig exported to%s %s.\n", colorGreen, colorReset, result.DestinationPath)
	case kubeconfig.MergeSummary:
		if result.DryRun {
			fmt.Fprintf(out, "%sDry run enabled:%s No changes have been made. The merged kubeconfig would have been saved to %s\n", colorYellow, colorReset, result.Destination)
		} else {
			fmt.Fprintf(out, "%sMerged kubeconfig saved to%s %s\n", colorGreen, colorReset, result.Destination)
		}
		fmt.Fprintln(out)
		writeLine(out, colorMagenta, "===============================================")
		writeLine(out, colorMagenta, "              KubeTidy Merge Summary           ")
		writeLine(out, colorMagenta, "===============================================")
		fmt.Fprintf(out, "%sStrategy:%s         %s\n", colorYellow, colorReset, result.Strategy)
		fmt.Fprintf(out, "%sFiles Merged:%s     %d\n", colorYellow, colorReset, result.FilesMerged)
		fmt.Fprintf(out, "%sClusters Merged:%s  %d\n", colorGreen, colorReset, result.ClustersMerged)
		fmt.Fprintf(out, "%sContexts Merged:%s  %d\n", colorGreen, colorReset, result.ContextsMerged)
		fmt.Fprintf(out, "%sUsers Merged:%s     %d\n", colorGreen, colorReset, result.UsersMerged)
		fmt.Fprintf(out, "%sDuplicates Kept:%s  c=%d ctx=%d u=%d\n", colorRed, colorReset, result.DuplicateClusters, result.DuplicateContexts, result.DuplicateUsers)
		writeLine(out, colorMagenta, "===============================================")
		fmt.Fprintln(out)
	case kubeconfig.CleanupResult:
		if result.BackupPath != "" {
			fmt.Fprintf(out, "%sBackup created at%s %s\n\n", colorGreen, colorReset, result.BackupPath)
		} else if result.DryRun {
			writeLine(out, colorYellow, "Dry run enabled: Skipping backup of the KubeConfig file.")
		}
		if len(result.RemovedClusters) == 0 {
			writeLine(out, colorGreen, "No clusters were removed.")
		} else if result.DryRun {
			fmt.Fprintf(out, "%sDry run enabled:%s The following clusters would be removed: %s\n", colorYellow, colorReset, strings.Join(result.RemovedClusters, ", "))
		} else {
			writeLine(out, colorGreen, "Removed clusters, users, and contexts related to unreachable clusters.")
			writeLine(out, colorGreen, "Kubeconfig cleaned and saved.")
		}
		fmt.Fprintln(out)
		writeLine(out, colorMagenta, "===============================================")
		writeLine(out, colorMagenta, "              KubeTidy Summary                 ")
		writeLine(out, colorMagenta, "===============================================")
		fmt.Fprintf(out, "%sClusters Checked:%s    %5d\n", colorYellow, colorReset, result.CheckedClusters)
		fmt.Fprintf(out, "%sClusters Removed:%s    %5d\n", colorRed, colorReset, len(result.RemovedClusters))
		fmt.Fprintf(out, "%sClusters Kept:%s       %5d\n", colorGreen, colorReset, result.CheckedClusters-len(result.RemovedClusters))
		writeLine(out, colorMagenta, "===============================================")
	case kubeconfig.ReportResult:
		writeLine(out, colorYellow, "KubeTidy Report")
		fmt.Fprintln(out)
		fmt.Fprintf(out, "%sSource paths:%s        %s\n", colorBrightCyan, colorReset, strings.Join(result.Source.Paths, ", "))
		fmt.Fprintf(out, "%sMerge strategy:%s      %s\n", colorYellow, colorReset, result.MergeStrategy)
		fmt.Fprintf(out, "%sClusters:%s            %d\n", colorGreen, colorReset, result.ClusterCount)
		fmt.Fprintf(out, "%sContexts:%s            %d\n", colorGreen, colorReset, result.ContextCount)
		fmt.Fprintf(out, "%sUsers:%s               %d\n", colorGreen, colorReset, result.UserCount)
		if result.CurrentContext != "" {
			fmt.Fprintf(out, "%sCurrent context:%s     %s\n", colorGreen, colorReset, result.CurrentContext)
		}
		if result.CurrentContextMissing {
			writeLine(out, colorRed, "Current context is missing from the merged view.")
		}
		if len(result.OrphanedContexts) > 0 {
			fmt.Fprintf(out, "%sOrphaned contexts:%s   %s\n", colorRed, colorReset, strings.Join(result.OrphanedContexts, ", "))
		}
		if len(result.UnusedUsers) > 0 {
			fmt.Fprintf(out, "%sUnused users:%s        %s\n", colorRed, colorReset, strings.Join(result.UnusedUsers, ", "))
		}
		if len(result.DuplicateServerGroups) > 0 {
			writeLine(out, colorMagenta, "Duplicate cluster servers:")
			for server, names := range result.DuplicateServerGroups {
				fmt.Fprintf(out, "  %s%s%s -> %s\n", colorBrightCyan, server, colorReset, strings.Join(names, ", "))
			}
		}
		if result.SourceDuplicateClusters+result.SourceDuplicateContexts+result.SourceDuplicateUsers > 0 {
			fmt.Fprintf(out, "%sSource duplicates:%s   c=%d ctx=%d u=%d\n", colorRed, colorReset, result.SourceDuplicateClusters, result.SourceDuplicateContexts, result.SourceDuplicateUsers)
		}
	case kubeconfig.DoctorResult:
		writeLine(out, colorYellow, "KubeTidy Doctor")
		fmt.Fprintln(out)
		fmt.Fprintf(out, "%sHealthy:%s             %t\n", ternaryColor(result.Healthy, colorGreen, colorRed), colorReset, result.Healthy)
		fmt.Fprintf(out, "%sIssues:%s              %d\n", colorYellow, colorReset, result.IssueCount)
		fmt.Fprintf(out, "%sCritical:%s            %d\n", colorRed, colorReset, result.CriticalCount)
		fmt.Fprintf(out, "%sWarnings:%s            %d\n", colorMagenta, colorReset, result.WarningCount)
		fmt.Fprintln(out)
		if len(result.Issues) == 0 {
			writeLine(out, colorGreen, "No issues detected.")
		} else {
			for _, issue := range result.Issues {
				fmt.Fprintf(out, "%s[%s]%s %s: %s\n", severityColor(issue.Severity), strings.ToUpper(issue.Severity), colorReset, issue.Category, issue.Message)
			}
		}
		fmt.Fprintln(out)
		writeLine(out, colorBrightCyan, "Doctor report summary:")
		return renderText(out, result.Report)
	default:
		return fmt.Errorf("unsupported text renderer for %T", value)
	}
	return nil
}

func writeLine(out io.Writer, color, message string) {
	fmt.Fprintf(out, "%s%s%s\n", color, message, colorReset)
}

func severityColor(severity string) string {
	switch strings.ToLower(strings.TrimSpace(severity)) {
	case "critical":
		return colorRed
	case "warning":
		return colorMagenta
	default:
		return colorGreen
	}
}

func ternaryColor(ok bool, whenTrue, whenFalse string) string {
	if ok {
		return whenTrue
	}
	return whenFalse
}
